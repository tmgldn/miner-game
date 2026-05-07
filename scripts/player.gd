extends CharacterBody2D
class_name Player

@export var SINK_VELOCITY := 70.0
@export var MAX_FALL_VELOCITY := 200.0
@export var JUMP_VELOCITY := -150.0

@export var LAND_MAX_SPEED := 70.0
@export var LAND_ACCELERATION := 20.0
@export var LAND_FRICTION := 20.0

@export var WATER_MAX_SPEED := 50.0
@export var WATER_ACCELERATION := 15.0
@export var WATER_FRICTION := 30.0

@export var OXYGEN_DRAIN_TIME := 0.75
@export var WATER_BUFFER := 0.1
@export var GAS_BUFFER := 0.1
@export var FIRE_BUFFER := 0.01
@export var LAVA_BUFFER := 0.01
@export var COYOTE_TIME := 0.08
@export var JUMP_BUFFER := 0.3
@export var DAMAGE_IMMUNITY_TIME := 1.5

var secs_since_on_ground := 999.0
var secs_since_jump_pressed := 999.0
var secs_since_in_water := 999.0
var secs_since_in_gas := 999.0
var secs_since_in_fire := 999.0
var secs_since_in_lava := 999.0
var secs_since_health_change := 999.0
var secs_since_damage := 999.0
var secs_since_oxygen_decrease := 999.0

func can_attempt_mine(tile_coords: Vector2i, player_coords: Vector2i) -> bool:
	if (
		tile_coords[0] != player_coords[0]
		and tile_coords[1] != player_coords[1]
		and GroundLayer.get_cell_source_id(Vector2i(tile_coords[0], player_coords[1])) == 0
		and GroundLayer.get_cell_source_id(Vector2i(player_coords[0], tile_coords[1])) == 0
	):
		return false
	
	return Game.is_mining_attemptable(tile_coords)

func can_mine(tile_coords: Vector2i, player_coords: Vector2i) -> bool:
	if (
		tile_coords[0] != player_coords[0]
		and tile_coords[1] != player_coords[1]
		and GroundLayer.get_cell_source_id(Vector2i(tile_coords[0], player_coords[1])) == 0
		and GroundLayer.get_cell_source_id(Vector2i(player_coords[0], tile_coords[1])) == 0
	):
		return false
	
	return Game.is_mineable(tile_coords)

var is_mining := false
var health := 3
var oxygen := 8

const MINING_ACTIONS: Array = [
	["mine_u", Vector2i(0, -1)],
	["mine_l", Vector2i(-1, 0)],
	["mine_r", Vector2i(1, 0)],
	["mine_d", Vector2i(0, 1)],
	["mine_ul", Vector2i(-1, -1)],
	["mine_ur", Vector2i(1, -1)],
	["mine_dl", Vector2i(-1, 1)],
	["mine_dr", Vector2i(1, 1)],
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

@onready var FluidLayer = %FluidLayer
@onready var GroundLayer = %GroundLayer
@onready var Game = %Game
@onready var PickaxeSprite = %PickaxeSprite
@onready var PlayerSprite = %PlayerSprite
@onready var OxygenIndicator = %OxygenIndicator
@onready var Meta = get_node("/root/Main/Meta")

func damage(dmg: int) -> void:
	if secs_since_damage >= DAMAGE_IMMUNITY_TIME:
		health = max(0, health - dmg)
		secs_since_damage = 0
		secs_since_health_change = 0
		if health <= 0:
			Meta.die()

var fix_position = null
var has_escaped := false

func _physics_process(delta: float) -> void:
	if has_escaped or health <= 0:
		return

	var fluid_coords_top: Vector2i = FluidLayer.local_to_map(global_position)
	if FluidLayer.is_water(fluid_coords_top):
		secs_since_in_water = 0
	elif FluidLayer.is_gas(fluid_coords_top):
		secs_since_in_gas = 0
	
	var fluid_coords_bottom: Vector2i = FluidLayer.local_to_map(global_position + Vector2(0, 6))
	if FluidLayer.is_fire(fluid_coords_top) or FluidLayer.is_fire(fluid_coords_bottom):
		secs_since_in_fire = 0
	elif FluidLayer.is_lava(fluid_coords_bottom):
		secs_since_in_lava = 0
	
	if is_on_floor():
		secs_since_on_ground = 0
	if Input.is_action_just_pressed("up"):
		secs_since_jump_pressed = 0

	var is_player_in_water := secs_since_in_water < WATER_BUFFER
	var is_player_in_gas := secs_since_in_gas < GAS_BUFFER
	var is_player_in_fire := secs_since_in_fire < FIRE_BUFFER
	var is_player_in_lava := secs_since_in_lava < LAVA_BUFFER
	var is_player_on_ground := secs_since_on_ground < COYOTE_TIME
	var has_player_tried_to_jump := secs_since_jump_pressed < JUMP_BUFFER
	var can_breathe: bool = not (is_player_in_water or is_player_in_gas)

	var MAX_SPEED: float = WATER_MAX_SPEED if is_player_in_water else LAND_MAX_SPEED
	var ACCELERATION: float = WATER_ACCELERATION if is_player_in_water else LAND_ACCELERATION
	var FRICTION: float = WATER_FRICTION if is_player_in_water else LAND_FRICTION
	var GRAVITY: Vector2 = get_gravity() * (0.5 if is_player_in_water else 1.0)
	
	if is_player_in_fire or is_player_in_lava:
		damage(2)
		if is_player_in_lava:
			velocity.y = JUMP_VELOCITY * 1.25

	if can_breathe:
		oxygen = 8
	elif secs_since_oxygen_decrease > OXYGEN_DRAIN_TIME:
		if oxygen <= 0:
			damage(1)
		else:
			oxygen = max(0, oxygen - 1)
		secs_since_oxygen_decrease = 0.0
	OxygenIndicator.texture.region.position.x = 8.0 * oxygen

	if health < 3:
		if secs_since_health_change >= 5.0 and can_breathe:
			health += 1
			secs_since_health_change = 0

	# apply gravity
	var gravity_mod: float = 1.0 if velocity.y >= 0 else (1.5 - (
		velocity.y / JUMP_VELOCITY
	))
	velocity += GRAVITY * gravity_mod * delta

	var is_minedir_pressed: bool = MINING_ACTIONS.any(func(pair: Array) -> bool: return Input.is_action_pressed(pair[0]))
	
	var player_coords: Vector2i = GroundLayer.local_to_map(global_position)
	if Input.is_action_pressed("show_mineable") and (not is_mining) and is_on_floor():
		%UIOverlayLayer.clear()
		for pair: Array in MINING_DIRECTIONS:
			var tile_coords: Vector2i = player_coords + pair[1]
			if can_mine(tile_coords, player_coords):
				%UIOverlayLayer.set_cell(tile_coords, 0, pair[0])
	else:
		%UIOverlayLayer.clear()
	
	var did_just_mine := false
	
	if (is_on_floor() and is_minedir_pressed) and not is_mining:
		var mine_success = null
		 
		for entry: Array in MINING_ACTIONS:
			if Input.is_action_pressed(entry[0]):
				if can_attempt_mine(player_coords + entry[1], player_coords):
					mine_success = entry
					break
		
		if mine_success:
			is_mining = true
			PickaxeSprite.play(mine_success[0])
			await Game.attempt_mine(player_coords + mine_success[1])
			is_mining = false
			did_just_mine = can_mine(player_coords + mine_success[1], player_coords)
	
	# this prevents the animation from being cancelled as layers are removed
	if not (did_just_mine or is_mining):
		PickaxeSprite.play("none")

	if is_mining:
		velocity.x = 0.0
		velocity.y = 0.0
		PlayerSprite.play("interact")
	else:
		# up - down
		if has_player_tried_to_jump and is_player_on_ground:
			velocity.y = JUMP_VELOCITY
			secs_since_jump_pressed = 9999.0
			secs_since_on_ground = 9999.0

		# left - right
		var h_direction := Input.get_axis("left", "right")
		if h_direction < 0:
			PlayerSprite.flip_h = true
			OxygenIndicator.offset.x = 12
		elif h_direction > 0:
			PlayerSprite.flip_h = false
			OxygenIndicator.offset.x = 0

		if is_player_on_ground:
			if h_direction == 0:
				PlayerSprite.play("idle")
			else:
				if is_player_in_water:
					PlayerSprite.play("swim")
				else:
					PlayerSprite.play("walk")
		else:
			if velocity.y < 0:
				if h_direction == 0:
					PlayerSprite.play("jump")
				else:
					PlayerSprite.play("jump_walk")
			else:
				if is_player_in_water:
					PlayerSprite.play("swim")
				elif velocity.y >= MAX_FALL_VELOCITY:
					if h_direction == 0:
						PlayerSprite.play("fall")
					else:
						PlayerSprite.play("fall_walk")
				else:
					PlayerSprite.play("walk")

		var h_velocity_weight: float = delta * (ACCELERATION if h_direction else FRICTION)
		velocity.x = lerp(velocity.x, h_direction * MAX_SPEED, h_velocity_weight)
		if is_player_in_water:
			velocity.y = min(velocity.y, SINK_VELOCITY)
	
	velocity.y = min(velocity.y, MAX_FALL_VELOCITY)

	if fix_position:
		position = fix_position
		velocity = Vector2(0, 0)

	# finish cycle
	move_and_slide()
	secs_since_on_ground += delta
	secs_since_jump_pressed += delta
	secs_since_in_water += delta
	secs_since_in_gas += delta
	secs_since_in_fire += delta
	secs_since_in_lava += delta
	secs_since_health_change += delta
	secs_since_damage += delta
	secs_since_oxygen_decrease += delta
