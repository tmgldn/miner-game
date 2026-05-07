extends Label
class_name HelpMessage

@export var message: String
@export var message_seconds_left: float

func _process(delta: float) -> void:
	visible = len(message) > 0 and message_seconds_left > 0
	text = message
	label_settings['font_color'] = Color(1, 1, 0.8, clamp(message_seconds_left, 0, 1))
