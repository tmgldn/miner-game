extends Area2D
class_name DiamondDoor

enum DoorState {
	PlayerNeedsDiamond,
	DoorNeedsDiamond,
	DoorOpening,
	DoorNeedsPlayer,
	DoorClosing,
	DoorClosed
}

@export var door_state: DoorState
@onready var Player: Player = %Player
@onready var DoorSprite: AnimatedSprite2D = $DoorSprite
@onready var DoorCollision: CollisionShape2D = $DoorCollider/DoorCollision
@onready var Meta = get_node("/root/Main/Meta")

var time_until_animation_complete := 0.0

func _physics_process(delta: float) -> void:
	if time_until_animation_complete > 0.0:
		time_until_animation_complete -= delta
		if time_until_animation_complete <= 0.0:
			time_until_animation_complete = 0.0
			if door_state == DoorState.DoorOpening:
				door_state = DoorState.DoorClosing
				time_until_animation_complete = 1.0
			elif door_state == DoorState.DoorClosing:
				door_state = DoorState.DoorClosed
	
	match door_state:
		DoorState.PlayerNeedsDiamond:
			DoorSprite.play('player_needs_diamond')
		DoorState.DoorNeedsDiamond:
			DoorSprite.play('door_needs_diamond')
		DoorState.DoorNeedsPlayer:
			DoorSprite.play('door_needs_player')
		DoorState.DoorOpening:
			DoorSprite.play('door_opening')
			Player.fix_position = global_position + Vector2(-5, 0)
		DoorState.DoorClosing:
			DoorSprite.play('door_closing')
			DoorCollision.position = Vector2(-11, 0)
			(DoorCollision.shape as RectangleShape2D).size = Vector2(6, 16)
			Player.fix_position = global_position + Vector2(-3, 0)
		DoorState.DoorClosed:
			DoorSprite.play('door_closed')
			Player.fix_position = null

func _on_body_entered(body: Node2D) -> void:
	if body == Player:
		if door_state == DoorState.DoorNeedsDiamond:
			door_state = DoorState.DoorOpening
			time_until_animation_complete = 1.0
			if name == 'DiamondDoor4':
				Meta.victory()
			else:
				Meta.escaped_eruption()
		elif door_state == DoorState.DoorNeedsPlayer:
			door_state = DoorState.DoorClosing
			Meta.respawn_position = global_position + Vector2(6, 0)
			time_until_animation_complete = 1.0
