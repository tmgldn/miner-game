extends Label
class_name OreMessage

@export var ore_count: int
@export var ore_name: String
@export var ore_seconds_left: float

func _process(delta: float) -> void:
	visible = bool(ore_count and ore_name)
	text = "+" + str(ore_count) + " " + ore_name
	label_settings['font_color'] = Color(1, 1, 1, clamp(ore_seconds_left, 0, 0.7))
