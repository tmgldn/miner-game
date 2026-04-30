extends Camera2D

var actual_cam_pos: Vector2
var has_initialised: bool = false

func _ready() -> void:
	pass

var lerp_rate: float = 3
var shake_state: int = 0
var time_since_last_state: float = 0.0

@onready var C = get_node("/root/Main/SubViewportContainer")
@onready var Meta = get_node("/root/Main/Meta")

var prev_cam_offset = Vector2(0, 0)
var has_erupted: bool = false

func _process(delta: float) -> void:
	if has_initialised:
		if not has_erupted:
			has_erupted = not is_inf(Meta.game_state.erupted_time_timestamp)
			if has_erupted:
				lerp_rate = 0.0
		if lerp_rate < 3:
			lerp_rate += (delta + lerp_rate) * 0.02
		elif lerp_rate > 3:
			lerp_rate = 3
		
		var player_pos = %Player.global_position
		var desired_pos: Vector2 = Vector2(
			clamp(player_pos[0], 168.0, 328.0),
			clamp(player_pos[1] + (
				-16.0 if has_erupted else 24.0
			), 92.0, 3118.0)
		)
		
		actual_cam_pos = actual_cam_pos.lerp(desired_pos, delta * lerp_rate)
		var cam_offset: Vector2 = actual_cam_pos.round() - actual_cam_pos
		if shake_state > 0 and shake_state < 8:
			var extra_offset = Vector2(0, 2)
			if shake_state == 2:
				extra_offset = Vector2(-1, -1)
			elif shake_state == 3:
				extra_offset = Vector2(1, 0)
			elif shake_state == 4:
				extra_offset = Vector2(-1, 0)
			elif shake_state == 5:
				extra_offset = Vector2(1, 0)
			if shake_state == 6:
				extra_offset = Vector2(-1, 0)
			elif shake_state == 7:
				extra_offset = Vector2(1, 0)
			cam_offset += extra_offset
			time_since_last_state += delta
			if time_since_last_state > (0.05 * (shake_state ** 0.5)):
				shake_state += 1
				time_since_last_state = 0

		if cam_offset != prev_cam_offset:
			C.material.set_shader_parameter("cam_offset", cam_offset)
			prev_cam_offset = cam_offset
		
		global_position = actual_cam_pos.round()
	else:
		actual_cam_pos = %Player.global_position
		global_position = actual_cam_pos.round()
		has_initialised = true
