extends Camera2D

var actual_cam_pos: Vector2
var has_run: bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if has_run:
		actual_cam_pos = actual_cam_pos.lerp(%Player.global_position, delta * 3)

		get_parent().get_parent().get_parent().material.set_shader_parameter(
			"cam_offset",
			(actual_cam_pos.round() - actual_cam_pos)
		)

		global_position = actual_cam_pos.round()
	else:
		actual_cam_pos = %Player.global_position
		global_position = actual_cam_pos.round()
		has_run = true
