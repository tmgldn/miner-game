extends Control

enum MetaState {
	StartScreen,
	InGame,
	InGamePaused,
	EndScreen
}

const INITIAL_GAME_STATE = {
	score = 0,
	eruption_time_timestamp = INF,
	erupted_time_timestamp = INF
}

var last_meta_state: MetaState = MetaState.EndScreen
var meta_state: MetaState = MetaState.StartScreen
var game_state = INITIAL_GAME_STATE.duplicate()
var game_scene = preload("res://game.tscn")
var pause_time: float = -1

func _process(delta: float) -> void:
	if meta_state != last_meta_state:
		if meta_state == MetaState.StartScreen:
			%StartScreen.visible = true
			%EndScreen.visible = false
			%BackgroundMusic.stream = preload("res://music/Komiku - A Tale is never forgotten - 01 The main reason we are here.mp3")
			%BackgroundMusic.play()
			%BackgroundMusic.playback_type 
			
		elif meta_state == MetaState.EndScreen:
			%StartScreen.visible = false
			%EndScreen.visible = true
			%BackgroundMusic.stream = preload("res://music/Komiku - A Tale is never forgotten - 10 Rest in the forest.mp3")
			%BackgroundMusic.play()
		else:
			%StartScreen.visible = false
			%EndScreen.visible = false
			%PauseMenu.visible = meta_state == MetaState.InGamePaused
			%BackgroundMusic.stream = preload("res://music/Komiku - A Tale is never forgotten - 04 Walk in the forest.mp3")
			%BackgroundMusic.play()
	
	last_meta_state = meta_state
	
	if Input.is_action_just_pressed('pause'):
		if meta_state == MetaState.InGame:
			get_tree().paused = true
			meta_state = MetaState.InGamePaused
			pause_time = Time.get_unix_time_from_system()
		elif meta_state == MetaState.InGamePaused:
			var pause_delta: float = Time.get_unix_time_from_system() - pause_time
			game_state.eruption_time_timestamp += pause_delta
			game_state.erupted_time_timestamp += pause_delta
			get_tree().paused = false
			meta_state = MetaState.InGame
	
	if (meta_state == MetaState.StartScreen or meta_state == MetaState.EndScreen) and Input.is_action_just_pressed('ui_accept'):
		for child in %SubViewport.get_children():
			%SubViewport.remove_child(child)
			
		game_state = INITIAL_GAME_STATE.duplicate()
		%SubViewport.add_child(game_scene.instantiate())
		meta_state = MetaState.InGame
		

func _update_end_screen(survived: bool):
	%EndScreenTitle.text = 'You escaped with' if survived else 'You died with'
	
	var score_str = str((game_state.score * 100))
	var i: int = len(score_str) - 3
	while i > 0:
		score_str = (
			score_str.substr(0, i) + ',' + 
			score_str.substr(i)
		)
		i -= 3
	%EndScreenScore.text = '£' + score_str

func escape():
	meta_state = MetaState.EndScreen
	_update_end_screen(true)
	
func die():
	meta_state = MetaState.EndScreen
	_update_end_screen(false)

func start_eruption_countdown():
	%BackgroundMusic.stream = preload("res://music/Komiku - A Tale is never forgotten - 05 Fight in the forest.mp3")
	%BackgroundMusic.play()

func erupt():
	var now = Time.get_unix_time_from_system()
	game_state.erupted_time_timestamp = now
	%BackgroundMusic.stream = preload("res://music/Komiku - A Tale is never forgotten - 09 A little boss fight for the road.mp3")
	%BackgroundMusic.play()
