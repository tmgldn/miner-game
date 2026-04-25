extends TileMapLayer

var next_update: float = Time.get_unix_time_from_system() + 0.3
const TIME_PER_CYCLE: float = 0.3

func _ready() -> void:
	next_update = Time.get_unix_time_from_system() + TIME_PER_CYCLE

func _physics_process(_delta: float) -> void:
	if Time.get_unix_time_from_system() >= next_update:
		tick_fluids()
		next_update = Time.get_unix_time_from_system() + TIME_PER_CYCLE

# --- tells fluids how to flow ---

func tick_fluids() -> void:
	for source_water_cell in get_water_sources():
		set_water(source_water_cell)

	var water_cells: Array[Vector2i] = get_water_cells()
	water_cells.append_array(get_water_sources())

	for water_cell in water_cells:
		var below_cell: Vector2i = Vector2i(water_cell[0], water_cell[1] + 1)
		if can_be_displaced_by_water(below_cell):
			swap_cell(water_cell, below_cell)
		else:
			var below_left_cell: Vector2i = Vector2i(water_cell[0] - 1, water_cell[1] + 1)
			var below_right_cell: Vector2i = Vector2i(water_cell[0] + 1, water_cell[1] + 1)
			
			var can_bottom_left: bool = can_be_displaced_by_water(below_left_cell)
			var can_bottom_right: bool = can_be_displaced_by_water(below_right_cell)
			
			if can_bottom_left and can_bottom_right:
				swap_cell(water_cell, below_left_cell if randf() < 0.5 else below_right_cell)
			elif can_bottom_left or can_bottom_right:
				swap_cell(water_cell, below_left_cell if can_bottom_left else below_right_cell)
			else:
				var left_cell: Vector2i = Vector2i(water_cell[0] - 1, water_cell[1])
				var right_cell: Vector2i = Vector2i(water_cell[0] + 1, water_cell[1])
				
				var can_left: bool = can_be_displaced_by_water(left_cell)
				var can_right: bool = can_be_displaced_by_water(right_cell)

				if can_left and can_right:
					swap_cell(water_cell, left_cell if randf() < 0.5 else right_cell)
				elif can_left or can_right:
					swap_cell(water_cell, left_cell if can_left else right_cell)
	for source_water_cell in get_water_sources():
		set_empty(source_water_cell)

# --- helpers ---

func is_empty(coords: Vector2i) -> bool:
	return (not is_solid(coords)) and %FluidLayer.get_cell_atlas_coords(coords) == Vector2i(-1, -1)
func is_solid(coords: Vector2i) -> bool:
	return %GroundLayer.get_cell_atlas_coords(Vector2i(coords[0] >> 1, coords[1] >> 1)) != Vector2i(-1, -1)
func is_gas(coords: Vector2i) -> bool:
	return %FluidLayer.get_cell_atlas_coords(coords) == Vector2i(1, 1)
func is_water(coords: Vector2i) -> bool:
	return %FluidLayer.get_cell_atlas_coords(coords) == Vector2i(0, 1)

func can_be_displaced_by_water(coords: Vector2i):
	return is_empty(coords) or is_gas(coords)

func set_empty(coords: Vector2i) -> void: # does not empty ground tile
	%FluidLayer.set_cell(coords, -1)
func set_gas(coords: Vector2i) -> void:
	%FluidLayer.set_cell(coords, 0, Vector2i(1, 1))
func set_water(coords: Vector2i) -> void:
	%FluidLayer.set_cell(coords, 0, Vector2i(0, 1))

func swap_cell(a: Vector2i, b: Vector2i) -> void:
	var temp = %FluidLayer.get_cell_atlas_coords(a)
	%FluidLayer.set_cell(a, 0, %FluidLayer.get_cell_atlas_coords(b))
	%FluidLayer.set_cell(b, 0, temp)

# this maps 16x16 grid tile locations for sapphires to their bottom two 8x8 subtiles
func get_water_sources() -> Array[Vector2i]:
	var output_locs: Array[Vector2i] = []
	for loc in %GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(0, 3)): # (0, 6)
		output_locs.append(Vector2i(loc[0] * 2, loc[1] * 2 + 1))
		output_locs.append(Vector2i(loc[0] * 2 + 1, loc[1] * 2 + 1))
	return output_locs

# this maps 16x16 grid tile locations for emeralds to their top two 8x8 subtiles
func get_gas_sources() -> Array[Vector2i]:
	var output_locs: Array[Vector2i] = []
	for loc in %GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(0, 7)):
		output_locs.append(Vector2i(loc[0] * 2, loc[1] * 2))
		output_locs.append(Vector2i(loc[0] * 2 + 1, loc[1] * 2))
	return output_locs

func get_water_cells() -> Array[Vector2i]:
	var water_cells: Array[Vector2i] = get_used_cells_by_id(0, Vector2i(0, 1))
	water_cells.reverse()
	return water_cells
	
func get_gas_cells() -> Array[Vector2i]:
	return get_used_cells_by_id(0, Vector2i(1, 1))
