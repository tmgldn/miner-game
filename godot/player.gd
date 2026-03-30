extends CharacterBody2D

const JUMP_VELOCITY: float = -150.0
var is_jumping: bool = false
var was_on_floor_recently: bool = false

# 70.0 but becomes 90.0 during eruption
const MAX_SPEED: float = 70.0
const ACCELERATION: float = 20.0
const FRICTION: float = 20.0

var timer_id = 0

func set_disable_jump_after_delay():
	var new_timer_id = ++self.timer_id
	await get_tree().create_timer(0.1).timeout
	if self.timer_id == new_timer_id:
		was_on_floor_recently = false
		
func can_mine(tile_coords: Vector2i, player_coords: Vector2i) -> bool:
	if (
		tile_coords[0] != player_coords[0]
		and tile_coords[1] != player_coords[1]
		and %Ground.get_cell_source_id(Vector2i(tile_coords[0], player_coords[1])) == 0
		and %Ground.get_cell_source_id(Vector2i(player_coords[0], tile_coords[1])) == 0
	):
		return false
	
	return %Game.is_mineable(tile_coords)

var is_mining: bool = false

const MINING_ACTIONS: Array = [
	["mine_u", Vector2i(0, -1)],
	["mine_l", Vector2i(-1, 0)],
	["mine_r", Vector2i(1, 0)],
	["mine_d", Vector2i(0, 1)],
	["mine_ul", Vector2i(-1, -1), Vector2i(-1, 0)],
	["mine_ur", Vector2i(1, -1), Vector2i(1, 0)],
	["mine_dl", Vector2i(-1, 1), Vector2i(-1, 0)],
	["mine_dr", Vector2i(1, 1), Vector2i(1, 0)],
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

func _physics_process(delta: float) -> void:	
	var can_jump: bool = is_on_floor() or (was_on_floor_recently and not is_jumping)
	
	if is_on_floor():
		is_jumping = false
		was_on_floor_recently = true
	else:
		if was_on_floor_recently:
			set_disable_jump_after_delay()
		var gravity_mod = 1 if velocity.y >= 0 else (1.5 - (
			velocity.y / JUMP_VELOCITY
		))
		velocity += get_gravity() * gravity_mod * delta

	var is_minedir_pressed = MINING_ACTIONS.any(func (pair): return Input.is_action_pressed(pair[0]))
	var player_coords: Vector2i = %Ground.local_to_map(global_position)
	
	if Input.is_action_pressed("show_mineable") and (not is_mining) and is_on_floor():
		%UIOverlay.clear()
		for pair in MINING_DIRECTIONS:
			var tile_coords = player_coords + pair[1]
			if can_mine(tile_coords, player_coords):
				%UIOverlay.set_cell(tile_coords, 0, pair[0])
	else:
		%UIOverlay.clear()
	
	if (is_on_floor() and is_minedir_pressed) and not is_mining:
		var tile_delta = null
		 
		for entry in MINING_ACTIONS:
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
		if can_jump and Input.is_action_just_pressed("up") and not Input.is_action_pressed('mine_mode'):
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			was_on_floor_recently = false

		var direction := Input.get_axis("left", "right")
		if direction < 0:
			%PlayerSprite.flip_h = true
		elif direction > 0:
			%PlayerSprite.flip_h = false
			
		if direction == 0:
			%PlayerSprite.play("idle")
		else:
			%PlayerSprite.play("walk")
	
		var velocity_weight: float = delta * (ACCELERATION if direction else FRICTION)
		velocity.x = lerp(velocity.x, direction * MAX_SPEED, velocity_weight)

	move_and_slide()
