extends Label

func _process(delta: float) -> void:
	var score_str = str((%Meta.game_state.score * 100))
	var i: int = len(score_str) - 3
	while i > 0:
		score_str = (
			score_str.substr(0, i) + ',' + 
			score_str.substr(i)
		)
		i -= 3
	text = '£' + score_str
