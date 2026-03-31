extends Area2D

@onready var timer_text: Label = get_node("/root/Main/Overlay/TopRight/TimeLeftText")

enum LavaState { Inactive, Pending, Active }
var camera_y_at_eruption: float
var eruption_timestamp: float = INF

var time_lava_off_screen: float = 0
const LAVA_PIXELS_START_DELTA = 100
const LAVA_RISE_MIN_PIXELS_PER_SEC = 10

func _process(delta: float) -> void:
	if not is_inf(timer_text.erupted_time_timestamp):
		var next_y: float
		if is_inf(eruption_timestamp):
			eruption_timestamp = timer_text.erupted_time_timestamp
			camera_y_at_eruption = %Camera.global_position.y + LAVA_PIXELS_START_DELTA
		if %Player.global_position.y < global_position.y - (LAVA_PIXELS_START_DELTA * 1.4):
			time_lava_off_screen += delta
		
		next_y = camera_y_at_eruption - round(
			((Time.get_unix_time_from_system() - eruption_timestamp) * LAVA_RISE_MIN_PIXELS_PER_SEC)
			+
			(time_lava_off_screen * LAVA_RISE_MIN_PIXELS_PER_SEC)
		)
		
		global_position = Vector2(
			0,
			clamp(next_y, max(-160, %Camera.global_position.y - LAVA_PIXELS_START_DELTA), 3200.0)
		)
