extends Node

@onready var Ground: TileMapLayer = %Ground
@onready var GroundOverlay: TileMapLayer = %GroundOverlay
@onready var TileInfo: Node = %TileInfo
@onready var Generate: Node = $Generate
@onready var score_text: Label = get_node("/root/Main/Overlay/TopRight/ScoreText")
@onready var timer_text: Label = get_node("/root/Main/Overlay/TopRight/TimeLeftText")

func _ready() -> void:
	add_points(0)
	Generate.initialise_grid(round(Time.get_unix_time_from_system()))

func tile_coords_to_data(coords: Vector2i) -> Dictionary:
	var ground: Vector2i = Ground.get_cell_atlas_coords(coords) if Ground.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
	var overlay: Vector2i = GroundOverlay.get_cell_atlas_coords(coords) if GroundOverlay.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
	return TileInfo.atlas_coords_to_data(ground, overlay)

func add_points(points: int) -> void:
	if score_text.score == 0 and points > 0:
		timer_text.eruption_time_timestamp = Time.get_unix_time_from_system() + 15
		%Camera.shake_state = 1
	score_text.score += points
	timer_text.eruption_time_timestamp += (points * 0.1) + (points ** 0.1)

func mine(coords: Vector2i) -> void:
	var tile_data = tile_coords_to_data(coords)
	var prev_index = tile_data.gi.index
	var next = tile_data.gi.data.t
	
	await get_tree().create_timer(tile_data.gi.data.s).timeout
	if next == 'Empty':
		Ground.set_cell(coords, -1)
		GroundOverlay.set_cell(coords, -1)
		add_points(tile_data.oi.data.p)
	else:
		var next_coord_pairs = TileInfo.TILE_NAME_LOOKUP[next].g.c
		Ground.set_cell(
			coords,
			0,
			next_coord_pairs[min(len(next_coord_pairs) - 1, prev_index)]
		)
	on_grid_change()

func wait_and_drop_if_still_there(i: int, j: int, was: String):
	await get_tree().create_timer(0.2).timeout
	
	var above_coords: Vector2i = Vector2i(i, j)
	var below_coords: Vector2i = Vector2i(i, j + 1)
	
	var above = tile_coords_to_data(above_coords)
	var above_tile_name = above.gi.name
	
	var below = tile_coords_to_data(below_coords)
	var below_tile_name = below.gi.name
	
	if above_tile_name == was and below_tile_name == 'Empty':
		var next_ground_name: String = above_tile_name.substr(0, len(above_tile_name) - 1) + 'F'
		var next_coord_pairs = TileInfo.TILE_NAME_LOOKUP[next_ground_name].g.c
		var next_coord = next_coord_pairs[min(len(next_coord_pairs) - 1, above.gi.index)]
		Ground.set_cell(above_coords, 0, next_coord)

		while true:
			await get_tree().create_timer(1.0).timeout

			above = tile_coords_to_data(above_coords)
			above_tile_name = above.gi.name
			
			below = tile_coords_to_data(below_coords)
			below_tile_name = below.gi.name

			if above_tile_name == next_ground_name and below_tile_name == 'Empty':
				var new_j = j + 1
				for row_j in range(j + 2, Generate.H):
					if tile_coords_to_data(Vector2i(i, row_j)).gi.name != 'Empty':
						new_j = row_j - 1
						break
				
				var player_coords: Vector2i = %Ground.local_to_map(%Player.global_position)
				if player_coords.x != i or player_coords.y < j or player_coords.y > new_j:
					var dropped_ground_name = above_tile_name.substr(0, len(above_tile_name) - 1) + '1'
					var dropped_coord_pairs = TileInfo.TILE_NAME_LOOKUP[dropped_ground_name].g.c
					var dropped_coord = dropped_coord_pairs[min(len(dropped_coord_pairs) - 1, above.gi.index)]
					
					Ground.set_cell(above_coords, -1)
					Ground.set_cell(Vector2i(i, new_j), 0, dropped_coord)
					
					if GroundOverlay.get_cell_source_id(above_coords) == 0:
						GroundOverlay.set_cell(Vector2i(i, new_j), 0, GroundOverlay.get_cell_atlas_coords(above_coords))
					GroundOverlay.set_cell(above_coords, -1)
					
					on_grid_change()
			else:
				break

func on_grid_change():
	# check for tiles that need to respond to gravity
	for i in range(0, Generate.W):
		for j in range(1, Generate.H):
			if tile_coords_to_data(Vector2i(i, j)).gi.name == 'Empty':
				var above_data = tile_coords_to_data(Vector2i(i, j - 1))
				var above_tile_name = above_data.gi.name
				if above_tile_name == 'Soil2' || above_tile_name == 'Rock3':
					wait_and_drop_if_still_there(i, j - 1, above_tile_name)

func is_mineable(tile_coords: Vector2i) -> bool:
	return tile_coords_to_data(tile_coords).gi.name != tile_coords_to_data(tile_coords).gi.data.t
