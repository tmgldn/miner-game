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
	var ground: Vector2i
	var overlay: Vector2i

	var tile_metadata: TileData = (%GroundLayer as TileMapLayer).get_cell_tile_data(coords)
	if tile_metadata != null and tile_metadata.get_custom_data("is_placeholder"):
		ground = Vector2i(-1, -1)
		overlay = Vector2i(-1, -1)
	else:
		ground = GroundLayer.get_cell_atlas_coords(coords) if GroundLayer.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
		overlay = GroundOverlayLayer.get_cell_atlas_coords(coords) if GroundOverlayLayer.get_cell_source_id(coords) == 0 else Vector2i(-1, -1)
	
	return TileInfo.atlas_coords_to_data(ground, overlay)

const SECONDS_PER_ORE = 3.0
const RUBY_EXPLOSION_SECONDS = 2.0

func add_points(points: int) -> void:
	if Meta().game_state.score == 0 and points > 0:
		pass
		#Meta().game_state.eruption_time_timestamp = Time.get_unix_time_from_system() + 15 - SECONDS_PER_ORE
		#%Camera.shake_state = 1
		#Meta().start_eruption_countdown()
	Meta().game_state.score += points
	Meta().game_state.eruption_time_timestamp += SECONDS_PER_ORE if points > 0 else 0.0


var PENDING_EXPLOSIONS: Dictionary = {}

func explode(coords: Vector2i) -> void:
	var tile_data = tile_coords_to_data(coords)
	PENDING_EXPLOSIONS.set(coords, null)
	GroundLayer.set_cell(coords, -1)
	GroundOverlayLayer.set_cell(coords, -1)
	add_points(tile_data.oi.data.p)
	on_grid_change()
	# all 4 subtiles become fire
	var top_left = coords * 2
	for di in range(-1, 3):
		for dj in range(-1, 3):
			var sub_coords = top_left + Vector2i(di, dj)
			if %FluidLayer.can_burn(sub_coords):
				%FluidLayer.set_fire(sub_coords)
			elif %FluidLayer.can_explode(sub_coords):
				explode(Vector2i(sub_coords[0] >> 1, sub_coords[1] >> 1))

func mine(coords: Vector2i) -> void:
	var tile_data = tile_coords_to_data(coords)
	var prev_index = tile_data.gi.index
	var next = tile_data.gi.data.t
	var next_next = TileInfo.TILE_NAME_LOOKUP[next].g.t

	if tile_data.oi.name == 'RubyE' and next == 'Empty':
		# activate explosion
		explode(coords)
	elif tile_data.oi.name == 'Ruby' and (next == 'Empty' or next_next == 'Empty'):
		GroundOverlayLayer.set_cell(coords, 0, TileInfo.OVERLAYS['RubyE'].c[0])

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
					
					var new_coords := Vector2i(i, new_j)

					GroundLayer.set_cell(above_coords, -1)
					GroundLayer.set_cell(new_coords, 0, dropped_coord)
					
					if GroundOverlayLayer.get_cell_source_id(above_coords) == 0:
						GroundOverlayLayer.set_cell(new_coords, 0, GroundOverlayLayer.get_cell_atlas_coords(above_coords))
					GroundOverlayLayer.set_cell(above_coords, -1)

					if PENDING_EXPLOSIONS.get(above_coords):
						var ref: Dictionary = PENDING_EXPLOSIONS.get(above_coords)
						ref.coords = new_coords
						PENDING_EXPLOSIONS.set(new_coords, ref)
						PENDING_EXPLOSIONS.set(above_coords, null)

					var sub_tl: bool = %FluidLayer.can_be_displaced_by_ground((new_coords * 2))
					var sub_bl: bool = %FluidLayer.can_be_displaced_by_ground((new_coords * 2) + Vector2i(0, 1))
					var sub_tr: bool = %FluidLayer.can_be_displaced_by_ground((new_coords * 2) + Vector2i(1, 0))
					var sub_br: bool = %FluidLayer.can_be_displaced_by_ground((new_coords * 2) + Vector2i(1, 1))

					for tuple: Array in [
						[sub_tl, sub_bl, (new_coords * 2)[0]],
						[sub_tr, sub_br, (new_coords * 2)[0] + 1],
					]:
						if tuple[0] and tuple[1]:
							# if both are non-empty in a column, move everything up 2
							for j_ in range(j, new_coords[1]):
								%FluidLayer.swap_cell(
									Vector2i(tuple[2], j_ * 2),
									Vector2i(tuple[2], j_ * 2 + 2),
								)
								%FluidLayer.swap_cell(
									Vector2i(tuple[2], j_ * 2 + 1),
									Vector2i(tuple[2], j_ * 2 + 3)
								)
						elif tuple[0] or tuple[1]:
							# if one is non-empty, move everything up 1
							# find bottom non-empty subtile
							for j_ in range(j * 2 + 1, (new_coords[1] - 1) * 2):
								%FluidLayer.swap_cell(
									Vector2i(tuple[2], j_),
									Vector2i(tuple[2], j_ + 1),
								)
							%FluidLayer.swap_cell(
								Vector2i(tuple[2], new_coords[1] * 2 - 1),
								Vector2i(tuple[2], new_coords[1] * 2 + (0 if tuple[0] else 1)),
							)
			else:
				break

func wait_and_explode(ref: Dictionary):
	if not PENDING_EXPLOSIONS.get(ref.coords):
		await get_tree().create_timer(RUBY_EXPLOSION_SECONDS).timeout
		var ref2 = PENDING_EXPLOSIONS.get(ref.coords)
		if ref == ref2:
			explode(ref.coords)

func on_grid_change():
	# check for tiles that need to respond to gravity
	var rect: Rect2i = %GroundLayer.get_used_rect()
	for i in range(rect.position.x, rect.position.x + rect.size.x):
		for j in range(rect.position.y, rect.position.y + rect.size.y):
			var coords = Vector2i(i, j)
			var tile_data = tile_coords_to_data(coords)

			if tile_data.oi.name == 'RubyE' and (not PENDING_EXPLOSIONS.get(coords)):
				var ref: Dictionary = {coords = coords}
				wait_and_explode(ref)
				PENDING_EXPLOSIONS.set(coords, ref)

			if tile_data.gi == null:
				print(tile_data, coords)

			if tile_data.gi.name == 'Empty':
				var above_data = tile_coords_to_data(Vector2i(i, j - 1))
				var above_tile_name = above_data.gi.name
				if above_tile_name == 'Soil2' || above_tile_name == 'Rock4' || above_tile_name == 'SoilP2' || above_tile_name == 'RockP4':
					wait_and_drop_if_still_there(i, j - 1, above_tile_name)

func is_mineable(tile_coords: Vector2i) -> bool:
	return tile_coords_to_data(tile_coords).gi.name != tile_coords_to_data(tile_coords).gi.data.t
