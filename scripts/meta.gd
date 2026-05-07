extends Control

enum MetaState {
	StartScreen,
	InGame,
}

var last_meta_state: MetaState = MetaState.InGame
var is_paused: bool = false
var meta_state: MetaState = MetaState.StartScreen
var game_scene = preload("res://scenes/game/game.tscn")
var active_stream := "res://music/01 The main reason we are here.mp3"
var prev_active_stream := ""
var active_stream_on_last_pause := ""

func _process(delta: float) -> void:
	if meta_state != last_meta_state:
		if meta_state == MetaState.StartScreen:
			%StartScreen.visible = true
			active_stream = "res://music/01 The main reason we are here.mp3"
			%BackgroundMusic.play()
		else:
			%StartScreen.visible = false
			active_stream = "res://music/04 Walk in the forest.mp3"
			%BackgroundMusic.play()
	
	last_meta_state = meta_state
	
	if Input.is_action_just_pressed('pause'):
		if meta_state == MetaState.InGame:
			var now_is_paused := !is_paused
			get_tree().paused = now_is_paused
			%PauseMenu.visible = now_is_paused
			if now_is_paused:
				active_stream_on_last_pause = active_stream
				active_stream = "res://music/04 Walk in the forest.mp3"
			else:
				active_stream = active_stream_on_last_pause
			
	
	if meta_state == MetaState.StartScreen and Input.is_action_just_pressed('ui_accept'):
		for child in %SubViewport.get_children():
			%SubViewport.remove_child(child)
		%SubViewport.add_child(game_scene.instantiate())
		meta_state = MetaState.InGame
	
	if active_stream != prev_active_stream:
		%BackgroundMusic.stream = load(active_stream)
		%BackgroundMusic.play()
		prev_active_stream = active_stream

func eruption():
	active_stream = "res://music/05 Fight in the forest.mp3"

func escaped_eruption():
	active_stream = "res://music/09 A little boss fight for the road.mp3"
