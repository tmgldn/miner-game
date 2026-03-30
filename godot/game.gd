extends Node

@onready var Ground: TileMapLayer = %Ground
@onready var GroundOverlay: TileMapLayer = %GroundOverlay
@onready var score_text: Label = get_node("/root/Main/Overlay/TopRight/ScoreText")

# Nested coord dict used to lookup tiles fast by tile coords
var COORD_LOOKUP: Dictionary[Vector2i, Variant] = {}
var score: int = 0
var grid: Array[Array]

func _ready() -> void:
	add_points(0)

	# fill COORD_LOOKUP
	for tile_id: G.TileId in G.TILE_DATA.keys():
		var tile_overlay_dict: Dictionary[Vector2i, G.TileId] = {}
		tile_overlay_dict = COORD_LOOKUP.get_or_add(G.TILE_DATA[tile_id].g, tile_overlay_dict)
		tile_overlay_dict[G.TILE_DATA[tile_id].o] = tile_id

	grid = $Generate.build_grid(1)
	$Generate.set_tiles_from_grid(grid)


func add_points(points: int) -> void:
	if score == 0 and points > 0:
		%Camera.shake_state = 1
	score += points
	var score_str = str((score * 100))
	var i: int = len(score_str) - 3
	while i > 0:
		score_str = (
			score_str.substr(0, i) + ',' + 
			score_str.substr(i)
		)
		i -= 3
	score_text.text = '£' + score_str

func tile_coords_to_id(coords: Vector2i) -> G.TileId:
	if Ground.get_cell_source_id(coords) == 0:
		var atlas_coords: Vector2i = Ground.get_cell_atlas_coords(coords)
		var tile_overlay_dict: Variant = COORD_LOOKUP.get(atlas_coords)
		assert(tile_overlay_dict != null)
		if tile_overlay_dict != null:
			var tile_id: G.TileId = tile_overlay_dict.get(GroundOverlay.get_cell_atlas_coords(coords) if GroundOverlay.get_cell_source_id(coords) == 0 else Vector2i(-1, -1))
			assert(tile_id != null)
			return G.TileId.Empty if tile_id == null else tile_id
		else:
			return G.TileId.Empty
	else:
		return G.TileId.Empty

func atlas_coords_to_id(ground: Vector2i, overlay: Vector2i) -> G.TileId:
	if ground == Vector2i(-1, -1):
		return G.TileId.Empty
	else:
		var tile_overlay_dict: Variant = COORD_LOOKUP.get(ground)
		assert(tile_overlay_dict != null)
		if tile_overlay_dict != null:
			var tile_id: G.TileId = tile_overlay_dict.get(overlay)
			assert(tile_id != null)
			return G.TileId.Empty if tile_id == null else tile_id
		else:
			return G.TileId.Empty

func mine(coords: Vector2i) -> void:
	var tile_id: G.TileId = tile_coords_to_id(coords)
	var tile_data: Dictionary = G.TILE_DATA[tile_id]
	await get_tree().create_timer(tile_data.s).timeout
	if tile_data.to == G.TileId.Empty:
		Ground.set_cell(coords, -1)
		if GroundOverlay.get_cell_source_id(coords) != -1:
			GroundOverlay.set_cell(coords, -1)
			add_points(
				tile_data.get('p', 0)
			)
		grid[coords[1]][coords[0]] = G.TileId.Empty
	else:
		Ground.set_cell(coords, 0, G.TILE_DATA[tile_data.to].g)
		var overlay: Vector2i = G.TILE_DATA[tile_data.to].o
		if overlay == Vector2i(-1, -1):
			GroundOverlay.set_cell(coords, -1)
		else:
			GroundOverlay.set_cell(coords, 0, overlay)
		grid[coords[1]][coords[0]] = tile_data.to
	on_grid_change()
	
func wait_and_drop_if_still_there(i: int, j: int, was: G.TileId):
	await get_tree().create_timer(0.2).timeout
	if grid[i][j] == was and grid[i + 1][j] == G.TileId.Empty:
		var pending_ground_tile_coords = G.TILE_DATA[G.TileId.Soil___].g if G.TILE_DATA[was].g == G.TILE_DATA[G.TileId.Soil__].g else G.TILE_DATA[G.TileId.Rock____].g
		var pending_tile_id = atlas_coords_to_id(pending_ground_tile_coords, G.TILE_DATA[was].o)
		grid[i][j] = pending_tile_id
		$Generate.set_tiles_from_grid(grid)

		while true:
			await get_tree().create_timer(1.0).timeout
			if grid[i][j] == pending_tile_id and grid[i + 1][j] == G.TileId.Empty:
				var new_i = i + 1
				for row_i in range(i + 2, len(grid)):
					if grid[row_i][j] != G.TileId.Empty:
						new_i = row_i - 1
						break
				var player_coords: Vector2i = %Ground.local_to_map(%Player.global_position)
				if player_coords.x != j or player_coords.y < i or player_coords.y > new_i:
					var next_ground_tile_coords = G.TILE_DATA[G.TileId.Soil_].g if G.TILE_DATA[pending_tile_id].g == G.TILE_DATA[G.TileId.Soil___].g else G.TILE_DATA[G.TileId.Rock__].g
					var next_overlay_tile_coords = G.TILE_DATA[pending_tile_id].o
					var next_tile_id = atlas_coords_to_id(next_ground_tile_coords, next_overlay_tile_coords)
					grid[i][j] = G.TileId.Empty
					grid[new_i][j] = next_tile_id
					$Generate.set_tiles_from_grid(grid)
					on_grid_change()
			else:
				break
	
func on_grid_change():
	# check for tiles that need to respond to gravity
	for i in range(0, len(grid) - 1):
		for j in range(0, len(grid[i])):
			var ground_tile_coords = G.TILE_DATA[grid[i][j]].g
			if (
				ground_tile_coords == G.TILE_DATA[G.TileId.Soil__].g or
				ground_tile_coords == G.TILE_DATA[G.TileId.Rock___].g
			) and grid[i + 1][j] == G.TileId.Empty:
				wait_and_drop_if_still_there(i, j, grid[i][j])

func is_mineable(tile_coords: Vector2i) -> bool:
	var tile_id: G.TileId = tile_coords_to_id(tile_coords)
	return G.TILE_DATA[tile_id].to != tile_id
