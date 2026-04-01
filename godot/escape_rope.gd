extends Area2D

@onready var Lava: Area2D = %Lava

func _process(delta: float) -> void:
	if not visible and not is_inf(Lava.eruption_timestamp):
		visible = true
