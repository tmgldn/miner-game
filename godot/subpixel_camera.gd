extends Camera2D

var actual_cam_pos: Vector2
var has_run: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if has_run:
		# bound
		var player_pos = %Player.global_position
		var desired_pos: Vector2 = Vector2(
			clamp(player_pos[0], 168.0, 328.0),
			clamp(player_pos[1], 92.0, 1000.0)
		)
		#var desired_pos = player_pos
		
		actual_cam_pos = actual_cam_pos.lerp(desired_pos, delta * 3)
		
		get_node("/root/Main/SubViewportContainer").material.set_shader_parameter(
			"cam_offset",
			actual_cam_pos.round() - actual_cam_pos
		)

		global_position = actual_cam_pos.round()
	else:
		actual_cam_pos = %Player.global_position
		global_position = actual_cam_pos.round()
		has_run = true
