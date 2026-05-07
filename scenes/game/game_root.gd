extends Node2D
class_name GameRoot

@onready var Player = %Player

var pending_move

func _ready() -> void:
	if pending_move:
		Player.position = pending_move
		pending_move = null

func move_player(coords: Vector2) -> void:
	if is_node_ready():
		Player.position = coords
	else:
		pending_move = coords
