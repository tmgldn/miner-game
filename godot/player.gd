extends CharacterBody2D

const JUMP_VELOCITY: float = -170.0
var is_jumping: bool = false
var was_on_floor: bool = false

const MAX_SPEED: float = 70.0
const ACCELERATION: float = 20.0
const FRICTION: float = 20.0

#if Input.is_action_pressed("ui_accept") and is_on_floor():
	#velocity.x = 0
#else:

func _physics_process(delta: float) -> void:	
	# allows jumping one extra frame after leaving the floor
	# to aid jumping after stepping off a ledge
	var can_jump: bool = is_on_floor() or (was_on_floor and not is_jumping)
	
	if is_on_floor():
		is_jumping = false
	else:
		velocity += get_gravity() * 2.0 * delta

	if can_jump and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY
		is_jumping = true

	var direction := Input.get_axis("ui_left", "ui_right")
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
	
	# for next frame
	if is_on_floor():
		was_on_floor = true
	else:
		was_on_floor = false
