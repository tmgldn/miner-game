extends Area2D

@export var message: String
@onready var player: Player = %Player

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		%Messages.set_help_message(message)

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		%Messages.set_help_message(message, 1.8)
