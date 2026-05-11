extends Control

enum MetaState {
	StartScreen,
	InGame,
	DeathScreen
}

var last_meta_state: MetaState = MetaState.InGame
var is_paused: bool = false
var meta_state: MetaState = MetaState.StartScreen
var game_scene = preload("res://scenes/game/game.tscn")
var active_stream := "res://music/01 The main reason we are here.mp3"
var prev_active_stream := ""
var active_stream_on_last_pause := ""
var respawn_position := Vector2(49, 24)

func _process(delta: float) -> void:
	if meta_state != last_meta_state:
		if meta_state == MetaState.StartScreen:
			%StartScreen.visible = true
			%DeathScreen.visible = false
			active_stream = "res://music/01 The main reason we are here.mp3"
		elif meta_state == MetaState.InGame:
			%StartScreen.visible = false
			%DeathScreen.visible = false
			active_stream = "res://music/04 Walk in the forest.mp3"
		else:
			%StartScreen.visible = false
			%DeathScreen.visible = true
			active_stream = "res://music/06 Die in the forest.mp3"
	
	last_meta_state = meta_state
	
	if Input.is_action_just_pressed('pause'):
		if meta_state == MetaState.InGame:
			var now_is_paused := !is_paused
			get_tree().paused = now_is_paused
			%PauseMenu.visible = now_is_paused
			is_paused = now_is_paused
			if now_is_paused:
				active_stream_on_last_pause = active_stream
				active_stream = "res://music/04 Walk in the forest.mp3"
			else:
				active_stream = active_stream_on_last_pause
	
	if (meta_state == MetaState.StartScreen or meta_state == MetaState.DeathScreen) and Input.is_action_just_pressed('ui_accept'):
		for child in %SubViewport.get_children():
			%SubViewport.remove_child(child)
		var game_root: GameRoot = game_scene.instantiate()
		%SubViewport.add_child(game_root)
		meta_state = MetaState.InGame
	
	if active_stream != prev_active_stream:
		%BackgroundMusic.stream = load(active_stream)
		%BackgroundMusic.play()
		prev_active_stream = active_stream

func eruption(level: int):
	active_stream = "res://music/09 A little boss fight for the road.mp3" if level >= 4 else "res://music/05 Fight in the forest.mp3"

func escaped_eruption():
	active_stream = "res://music/04 Walk in the forest.mp3"

func victory():
	active_stream = "res://music/16 The only reason we end here.mp3"

func respawn():
	meta_state = MetaState.DeathScreen
