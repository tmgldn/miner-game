extends Label

func _process(delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	if now < %Meta.game_state.erupted_time_timestamp:
		if is_inf(%Meta.game_state.eruption_time_timestamp):
			text = ''
		else:
			if now >= %Meta.game_state.eruption_time_timestamp:
				%Meta.game_state.erupted_time_timestamp = now
				text = 'erupting!'
				%TimeLeftHeaderText.visible = false
			else:
				text = str(floor((%Meta.game_state.eruption_time_timestamp - now) * 10) / 10) + 's'
				%TimeLeftText.visible = true
				%TimeLeftHeaderText.visible = true
	else:
		pass
