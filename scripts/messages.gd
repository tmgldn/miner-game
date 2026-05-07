extends VBoxContainer

const ORE_MSG_SHOW_SECS = 2.0

var counts = {
	diamond=[0, 0.0],
	ruby=[0, 0.0],
	emerald=[0, 0.0],
	sapphire=[0, 0.0],
	gold=[0, 0.0],
	silver=[0, 0.0],
	iron=[0, 0.0],
}

var help_message: Array = ["", 0.0]

var player_message_scene = preload("res://scenes/game/player_message.tscn")

func by_least_recent_to_most(a: Array, b: Array) -> bool:
	return b[1][1] < a[1][1]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# help message
	if help_message[1] > 0.0:
		$HelpMessage.message = help_message[0]
		help_message[1] -= delta
		$HelpMessage.message_seconds_left = help_message[1]
	
	# ore messages
	var showable_counts: Array[Array] = []
	for key in counts.keys():
		if counts[key][1] > 0.0:
			showable_counts.append([key, counts[key]])
			counts[key][1] -= delta
			if counts[key][1] <= 0.0:
				counts[key][0] = 0
				counts[key][1] = 0.0
	showable_counts.sort_custom(by_least_recent_to_most)
	
	for ore_message_id: int in range(1, 4):
		var message: OreMessage = get_node("OreMessage" + str(ore_message_id))
		
		if len(showable_counts) >= ore_message_id:
			var showable_count: Array = showable_counts[ore_message_id - 1]
			message.ore_name = showable_count[0]
			message.ore_count = showable_count[1][0]
			message.ore_seconds_left = showable_count[1][1]
		else:
			message.ore_name = ""
			message.ore_count = 0
			message.ore_seconds_left = 0.0

		ore_message_id += 1

func show_add_ore_message(ore: String):
	var lower_ore := ('Ruby' if ore == 'RubyE' else ore).to_lower()
	if counts.has(lower_ore): 
		counts[lower_ore][0] += 1
		counts[lower_ore][1] = ORE_MSG_SHOW_SECS

func set_help_message(msg: String, duration = 10000000.0):
	help_message[0] = msg
	help_message[1] = duration
