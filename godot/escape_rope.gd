extends Area2D

@onready var Meta = get_node("/root/Main/Meta")

func _process(delta: float) -> void:
	if not visible and not is_inf(Meta.game_state.eruption_time_timestamp):
		visible = true
