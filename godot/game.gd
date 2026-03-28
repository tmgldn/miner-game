extends Node


var score = 0
var grid: Array[Array]

func _ready() -> void:
	grid = $Generate.build_grid(1)
	$Generate.set_tiles_from_grid(grid)

@onready var score_text = get_node("/root/Main/Overlay/TopRight/ScoreText")

func add_points(points: int):
	score += points
	score_text.text = str(score)
