extends Label

var eruption_time_timestamp: float = INF
var erupted_time_timestamp: float = INF

func _process(delta: float) -> void:
	var now = Time.get_unix_time_from_system()
	if now < erupted_time_timestamp:
		if is_inf(eruption_time_timestamp):
			text = ''
		else:
			if now >= eruption_time_timestamp:
				erupted_time_timestamp = now
				text = 'erupting!'
				%TimeLeftHeaderText.visible = false
			else:
				text = str(floor((eruption_time_timestamp - now) * 10) / 10) + 's'
				%TimeLeftText.visible = true
				%TimeLeftHeaderText.visible = true
	else:
		pass
