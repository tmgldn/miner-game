extends Area2D

@onready var Meta: Node = get_node("/root/Main/Meta")

enum LavaState { Inactive, Pending, Active }
var camera_y_at_eruption: float

var time_lava_off_screen: float = 0
const LAVA_PIXELS_START_DELTA = 100
const LAVA_RISE_MIN_PIXELS_PER_SEC = 10

var has_already_run_eruption_effect: bool = false

func _process(delta: float) -> void:
	if not is_inf(Meta.game_state.erupted_time_timestamp):
		var next_y: float
		if not has_already_run_eruption_effect:
			has_already_run_eruption_effect = true
			camera_y_at_eruption = %Camera.global_position.y + LAVA_PIXELS_START_DELTA
		
		if %Player.global_position.y < global_position.y - (LAVA_PIXELS_START_DELTA * 1.4):
			time_lava_off_screen += delta
		
		next_y = camera_y_at_eruption - round(
			((Time.get_unix_time_from_system() - Meta.game_state.erupted_time_timestamp) * LAVA_RISE_MIN_PIXELS_PER_SEC)
			+
			(time_lava_off_screen * LAVA_RISE_MIN_PIXELS_PER_SEC)
		)
		
		global_position = Vector2(
			0,
			clamp(next_y, max(-160, %Camera.global_position.y - LAVA_PIXELS_START_DELTA), 3200.0)
		)
