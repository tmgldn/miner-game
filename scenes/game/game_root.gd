extends Node2D
class_name GameRoot

@onready var Player = %Player
@onready var Meta = get_node("/root/Main/Meta")

func _ready() -> void:
	Player.position = Meta.respawn_position
