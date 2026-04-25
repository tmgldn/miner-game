extends Node

@onready var GroundLayer: TileMapLayer = %GroundLayer
@onready var GroundOverlayLayer: TileMapLayer = %GroundOverlayLayer
@onready var TileInfo: Node = %TileInfo
@onready var Generate: Node = $Generate

func Meta():
	return get_node("/root/Main/Meta")

func _ready() -> void:
	add_points(0)
	Generate.initialise_grid(round(Time.get_unix_time_from_system()))

func tile_coords_to_data(coords: Vector2i) -> Dictionary:
	var ground: Vector2i = GroundLayer.get_cell_atlas_coords(coords) if GroundLayer.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
	var overlay: Vector2i = GroundOverlayLayer.get_cell_atlas_coords(coords) if GroundOverlayLayer.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
	return TileInfo.atlas_coords_to_data(ground, overlay)
	
const SECONDS_PER_ORE = 3.0

func add_points(points: int) -> void:
	if Meta().game_state.score == 0 and points > 0:
		Meta().game_state.eruption_time_timestamp = Time.get_unix_time_from_system() + 15 - SECONDS_PER_ORE
		%Camera.shake_state = 1
		Meta().start_eruption_countdown()
	Meta().game_state.score += points
	Meta().game_state.eruption_time_timestamp += SECONDS_PER_ORE if points > 0 else 0

func mine(coords: Vector2i) -> void:
	var tile_data = tile_coords_to_data(coords)
	var prev_index = tile_data.gi.index
	var next = tile_data.gi.data.t
	
	await get_tree().create_timer(tile_data.gi.data.s).timeout
	if next == 'Empty':
		GroundLayer.set_cell(coords, -1)
		GroundOverlayLayer.set_cell(coords, -1)
		add_points(tile_data.oi.data.p)
	else:
		var next_coord_pairs = TileInfo.TILE_NAME_LOOKUP[next].g.c
		GroundLayer.set_cell(
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
		GroundLayer.set_cell(above_coords, 0, next_coord)

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
				
				var player_coords: Vector2i = %GroundLayer.local_to_map(%Player.global_position)
				if player_coords.x != i or player_coords.y < j or player_coords.y > new_j:
					var dropped_ground_name = above_tile_name.substr(0, len(above_tile_name) - 1) + '1'
					var dropped_coord_pairs = TileInfo.TILE_NAME_LOOKUP[dropped_ground_name].g.c
					var dropped_coord = dropped_coord_pairs[min(len(dropped_coord_pairs) - 1, above.gi.index)]
					
					GroundLayer.set_cell(above_coords, -1)
					GroundLayer.set_cell(Vector2i(i, new_j), 0, dropped_coord)
					
					if GroundOverlayLayer.get_cell_source_id(above_coords) == 0:
						GroundOverlayLayer.set_cell(Vector2i(i, new_j), 0, GroundOverlayLayer.get_cell_atlas_coords(above_coords))
					GroundOverlayLayer.set_cell(above_coords, -1)
					
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
