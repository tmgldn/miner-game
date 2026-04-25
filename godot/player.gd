extends CharacterBody2D

const SINK_VELOCITY: float = 70.0
const JUMP_VELOCITY: float = -150.0
var is_jumping := false
var was_on_floor_recently := false
var was_in_water_recently := false

# 70.0 but becomes 90.0 during eruption
const LAND_MAX_SPEED: float = 70.0
const LAND_ACCELERATION: float = 20.0
const LAND_FRICTION: float = 20.0

const WATER_MAX_SPEED: float = 50.0
const WATER_ACCELERATION: float = 15.0
const WATER_FRICTION: float = 30.0

var timer_id := 0

@onready var Meta := get_node("/root/Main/Meta")

func set_disable_jump_after_delay() -> void:
	var new_timer_id := ++self.timer_id
	await get_tree().create_timer(0.1).timeout
	if self.timer_id == new_timer_id:
		was_on_floor_recently = false
		
func can_mine(tile_coords: Vector2i, player_coords: Vector2i) -> bool:
	if (
		tile_coords[0] != player_coords[0]
		and tile_coords[1] != player_coords[1]
		and %GroundLayer.get_cell_source_id(Vector2i(tile_coords[0], player_coords[1])) == 0
		and %GroundLayer.get_cell_source_id(Vector2i(player_coords[0], tile_coords[1])) == 0
	):
		return false
	
	return %Game.is_mineable(tile_coords)

var is_mining := false
var health := 3
var is_in_lava := false

const MINING_ACTIONS: Array = [
	["mine_u", Vector2i(0, -1)],
	["mine_l", Vector2i(-1, 0)],
	["mine_r", Vector2i(1, 0)],
	["mine_d", Vector2i(0, 1)],
	["mine_ul", Vector2i(-1, -1)], # Vector2i(-1, 0)],
	["mine_ur", Vector2i(1, -1)], # Vector2i(1, 0)],
	["mine_dl", Vector2i(-1, 1)], # Vector2i(-1, 0)],
	["mine_dr", Vector2i(1, 1)], # Vector2i(1, 0)],
]

const MINING_DIRECTIONS = [
	[Vector2i(0, 0), Vector2i(0, -1)],
	[Vector2i(1, 0), Vector2i(1, 0)],
	[Vector2i(2, 0), Vector2i(0, 1)],
	[Vector2i(3, 0), Vector2i(-1, 0)],
	[Vector2i(4, 0), Vector2i(1, -1)],
	[Vector2i(5, 0), Vector2i(1, 1)],
	[Vector2i(6, 0), Vector2i(-1, -1)],
	[Vector2i(7, 0), Vector2i(-1, 1)],
]

var is_immune_to_damage := false

func add_damage_if_not_immune(damage: int) -> void:
	if not is_immune_to_damage:
		health = max(0, health - damage)
		if health <= 0:
			Meta.die()
		else:
			heal_timeout.cancel = true
			heal_timeout = {finished = false, cancel = false}
			start_healing(heal_timeout)
			is_immune_to_damage = true
			await get_tree().create_timer(1.0).timeout
			is_immune_to_damage = false

var heal_timeout := {finished = true, cancel = false}
func start_healing(timeout_obj: Dictionary) -> void:
	await get_tree().create_timer(5.0).timeout
	if not timeout_obj.cancel:
		health += 1
		if health < 3:
			heal_timeout = {finished = false, cancel = false}
			start_healing(heal_timeout)

var has_escaped := false

func _physics_process(delta: float) -> void:
	if has_escaped or health <= 0:
		return
	
	var is_in_water_: bool = %FluidLayer.get_cell_atlas_coords(%FluidLayer.local_to_map(global_position)) == Vector2i(0, 1)
	var is_in_water: bool = is_in_water_ or was_in_water_recently
	# var is_in_gas: bool = %FluidLayer.get_cell_atlas_coords(%FluidLayer.local_to_map(global_position)) == Vector2i(1, 1)
	
	var MAX_SPEED: float = WATER_MAX_SPEED if is_in_water else LAND_MAX_SPEED
	var ACCELERATION: float = WATER_ACCELERATION if is_in_water else LAND_ACCELERATION
	var FRICTION: float = WATER_FRICTION if is_in_water else LAND_FRICTION
	var GRAVITY: Vector2 = get_gravity() * (0.5 if is_in_water else 1.0)
	
	var can_jump := is_on_floor() or (was_on_floor_recently and not is_jumping)
	
	if is_in_lava:
		add_damage_if_not_immune(1)
		velocity.y = JUMP_VELOCITY * 1.25
		is_jumping = true
		was_on_floor_recently = false
	
	if health < 3 and heal_timeout.finished:
		heal_timeout = {finished = false, cancel = false}
		start_healing(heal_timeout)
	
	
	if is_on_floor():
		is_jumping = false
		was_on_floor_recently = true
	else:
		if was_on_floor_recently:
			set_disable_jump_after_delay()
		var gravity_mod: float = 1.0 if velocity.y >= 0 else (1.5 - (
			velocity.y / JUMP_VELOCITY
		))
		velocity += GRAVITY * gravity_mod * delta

	var is_minedir_pressed: bool = MINING_ACTIONS.any(func(pair: Array) -> bool: return Input.is_action_pressed(pair[0]))
	
	var player_coords: Vector2i = %GroundLayer.local_to_map(global_position)
	if Input.is_action_pressed("show_mineable") and (not is_mining) and is_on_floor():
		%UIOverlayLayer.clear()
		for pair: Array in MINING_DIRECTIONS:
			var tile_coords: Vector2i = player_coords + pair[1]
			if can_mine(tile_coords, player_coords):
				%UIOverlayLayer.set_cell(tile_coords, 0, pair[0])
	else:
		%UIOverlayLayer.clear()
	
	if (is_on_floor() and is_minedir_pressed) and not is_mining:
		var tile_delta = null
		 
		for entry: Array in MINING_ACTIONS:
			if Input.is_action_pressed(entry[0]):
				# if can be mined directly
				if can_mine(player_coords + entry[1], player_coords):
					tile_delta = entry[1]
					break
				# if can be mined indirectly, mine side first
				if len(entry) > 2 and %Game.is_mineable(player_coords + entry[1]) and can_mine(player_coords + entry[2], player_coords):
					tile_delta = entry[2]
					break
		
		if tile_delta != null:
			is_mining = true
			await %Game.mine(player_coords + tile_delta)
			is_mining = false

	if is_mining:
		velocity.x = 0.0
		velocity.y = 0.0
	else:
		# up - down
		if can_jump and Input.is_action_just_pressed("up"):
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			was_on_floor_recently = false

		# left - right
		var h_direction := Input.get_axis("left", "right")
		if h_direction < 0:
			%PlayerSprite.flip_h = true
		elif h_direction > 0:
			%PlayerSprite.flip_h = false

		if h_direction == 0:
			%PlayerSprite.play("idle")
		else:
			%PlayerSprite.play("walk")

		var h_velocity_weight: float = delta * (ACCELERATION if h_direction else FRICTION)
		velocity.x = lerp(velocity.x, h_direction * MAX_SPEED, h_velocity_weight)
		if is_in_water:
			velocity.y = min(velocity.y, SINK_VELOCITY)

	was_in_water_recently = is_in_water_

	move_and_slide()


func _on_lava_body_entered(body: Node2D) -> void:
	if body == $".":
		is_in_lava = true

func _on_lava_body_exited(body: Node2D) -> void:
	if body == $".":
		is_in_lava = false

func _on_escape_rope_body_entered(_body: Node2D) -> void:
	if not is_inf(Meta.game_state.erupted_time_timestamp):
		has_escaped = true
		global_position = Vector2(248, -25)
		Meta.escape()
