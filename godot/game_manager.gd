extends Node

var score = 0
@onready var ScoreText = $/root/Main/Overlay/TopRight/ScoreText

func add_points(points: int):
	if score == 0 and points > 0:
		lower_ladder()
	score += points
	ScoreText.text = str(score)

func lower_ladder():
	print('lower ladder!')
	%BehindGround.set_cell(
		Vector2(15, 0),
		0,
		Vector2(9, 4)
	)
	%BehindGround.set_cell(
		Vector2(15, 1),
		0,
		Vector2(9, 4)
	)
	%BehindGround.set_cell(
		Vector2(15, 2),
		0,
		Vector2(9, 5)
	)
	pass
