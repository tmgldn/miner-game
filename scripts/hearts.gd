extends Node2D

var previous_health = 3
var time_of_last_change: float = 0

func _physics_process(delta: float) -> void:
	var health = %Player.health
	if health <= 0:
		visible = false
	else:
		var now: float = Time.get_unix_time_from_system()
		if health != previous_health:
			time_of_last_change = now
			previous_health = health
		if time_of_last_change + 5.1 >= Time.get_unix_time_from_system():
			visible = true
			$Heart1.texture.region = Rect2(40, 0, 8, 8) if health >= 1 else Rect2(32, 0, 8, 8)
			$Heart2.texture.region = Rect2(40, 0, 8, 8) if health >= 2 else Rect2(32, 0, 8, 8)
			$Heart3.texture.region = Rect2(40, 0, 8, 8) if health >= 3 else Rect2(32, 0, 8, 8)
		else:
			visible = false
