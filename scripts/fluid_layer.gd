extends TileMapLayer

@onready var TileInfo := %TileInfo
@onready var Game := %Game
@onready var GroundLayer := %GroundLayer
@onready var GroundOverlayLayer := %GroundOverlayLayer

const TIME_PER_CYCLE: float = 0.075
const CYCLES_PER_FLUID: int = 4

var next_update := TIME_PER_CYCLE
var cycle_count := CYCLES_PER_FLUID

func _physics_process(delta: float) -> void:
	next_update -= delta
	if next_update <= 0:
		next_update += TIME_PER_CYCLE
		tick_fire()
		cycle_count -= 1
		if cycle_count <= 0:
			cycle_count = CYCLES_PER_FLUID
			tick_fluids()

# probability of rise given obstacle
const FIRE_RULES = {
	Vector2i(0, 3): { # Fire 0
		Vector2i(-1, -1): 0.3, # Empty
		Vector2i(0, 1): 0.0, # Water
		Vector2i(0, 2): 1.0, # Gas
		Vector2i(0, 3): 0.3, # Fire 0
		Vector2i(0, 4): 0.2, # Fire 1
		Vector2i(0, 5): 0.1, # Fire 2
		Vector2i(0, 6): 0.0, # Fire 3
		Vector2i(0, 11): 0.0, # Vent
	},
	Vector2i(0, 4): { # Fire 1
		Vector2i(-1, -1): 0.3, # Empty
		Vector2i(0, 1): 0.0, # Water
		Vector2i(0, 2): 1.0, # Gas
		Vector2i(0, 3): 0.3, # Fire 0
		Vector2i(0, 4): 0.2, # Fire 1
		Vector2i(0, 5): 0.1, # Fire 2
		Vector2i(0, 6): 0.0, # Fire 3
		Vector2i(0, 11): 0.0, # Vent
	},
	Vector2i(0, 5): { # Fire 2
		Vector2i(-1, -1): 0.3, # Empty
		Vector2i(0, 1): 0.0, # Water
		Vector2i(0, 2): 1.0, # Gas
		Vector2i(0, 3): 0.3, # Fire 0
		Vector2i(0, 4): 0.2, # Fire 1
		Vector2i(0, 5): 0.1, # Fire 2
		Vector2i(0, 6): 0.0, # Fire 3
		Vector2i(0, 11): 0.0, # Vent
	},
	Vector2i(0, 6): { # Fire 3
		Vector2i(-1, -1): 0.0, # Empty
		Vector2i(0, 1): 0.0, # Water
		Vector2i(0, 2): 0.5, # Gas
		Vector2i(0, 3): 0.3, # Fire 0
		Vector2i(0, 4): 0.2, # Fire 1
		Vector2i(0, 5): 0.1, # Fire 2
		Vector2i(0, 6): 0.0, # Fire 3
		Vector2i(0, 11): 0.0, # Vent
	},
}

func tick_fire() -> void:
	var has_tile_changed := false
	
	for atlas_coords in [
		Vector2i(0, 6),
		Vector2i(0, 5),
		Vector2i(0, 4),
		Vector2i(0, 3)
	]:
		for fire_coords in get_used_cells_by_id(0, atlas_coords):
			# die
			if atlas_coords[1] == 6:
				set_empty(fire_coords)
			else:
				set_fire(fire_coords, atlas_coords[1] + 1)
			# maybe rise
			for di in range(-1, 2, 1):
				var other_coords := Vector2i(fire_coords[0] + di, fire_coords[1] - 1)
				if is_solid(other_coords, true):
					if can_explode(other_coords):
						%Game.explode(Vector2i(other_coords[0] >> 1, other_coords[1] >> 1))
					else:
						var other_tile_coords := Vector2i(other_coords[0] >> 1, other_coords[1] >> 1)

						var curr_ground = TileInfo.GROUND_LOOKUP[%GroundLayer.get_cell_atlas_coords(other_tile_coords)]
						var next_ground = curr_ground.name
						match curr_ground.name:
							"Soil0":
								next_ground = "Soil1"
							"Soil1", "Soil2":
								next_ground = "Soil2"
							"Rock0":
								next_ground = "Rock1"
							"Rock1":
								next_ground = "Rock2"
							"Rock2", "Rock3":
								next_ground = "Rock3"
						if next_ground != curr_ground.name:
							%GroundLayer.set_cell(
								other_tile_coords,
								0,
								TileInfo.GROUNDS_WITH_OVERLAYS[next_ground]['c'][
									min(
										curr_ground.index,
										len(TileInfo.GROUNDS_WITH_OVERLAYS[next_ground]['c']) - 1
									)
								]
							)
							has_tile_changed = true
				else:
					var other_atlas_coords: Vector2i = get_cell_atlas_coords(other_coords)
					if randf() <= FIRE_RULES[atlas_coords][other_atlas_coords]:
						# rise
						set_fire(other_coords, atlas_coords[0])
	if has_tile_changed:
		%Game.on_grid_change()

func tick_fluids() -> void:
	# water
	for source_water_cell in get_water_sources():
		set_water(source_water_cell)

	var water_cells: Array[Vector2i] = get_water_cells()
	water_cells.sort_custom(sort_fn_desc)
	
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

	# gas
	for source_gas_cell in get_gas_sources():
		set_gas(source_gas_cell)

	var gas_cells: Array[Vector2i] = get_gas_cells()
	gas_cells.sort_custom(sort_fn_asc)

	for gas_cell in gas_cells:
		var above_cell: Vector2i = Vector2i(gas_cell[0], gas_cell[1] - 1)
		if can_be_displaced_by_gas(above_cell):
			swap_cell(gas_cell, above_cell)
		else:
			var above_left_cell: Vector2i = Vector2i(gas_cell[0] - 1, gas_cell[1] - 1)
			var above_right_cell: Vector2i = Vector2i(gas_cell[0] + 1, gas_cell[1] - 1)
			
			var can_top_left: bool = can_be_displaced_by_gas(above_left_cell)
			var can_top_right: bool = can_be_displaced_by_gas(above_right_cell)
			
			if can_top_left and can_top_right:
				swap_cell(gas_cell, above_left_cell if randf() < 0.5 else above_right_cell)
			elif can_top_left or can_top_right:
				swap_cell(gas_cell, above_left_cell if can_top_left else above_right_cell)
			else:
				var left_cell: Vector2i = Vector2i(gas_cell[0] - 1, gas_cell[1])
				var right_cell: Vector2i = Vector2i(gas_cell[0] + 1, gas_cell[1])
				
				var can_left: bool = can_be_displaced_by_gas(left_cell)
				var can_right: bool = can_be_displaced_by_gas(right_cell)

				if can_left and can_right:
					swap_cell(gas_cell, left_cell if randf() < 0.5 else right_cell)
				elif can_left or can_right:
					swap_cell(gas_cell, left_cell if can_left else right_cell)

	for source_gas_cell in get_gas_sources():
		set_empty(source_gas_cell)

# --- helpers ---

func is_empty(coords: Vector2i) -> bool:
	return (not is_solid(coords)) and get_cell_atlas_coords(coords) == Vector2i(-1, -1)
func is_solid(coords: Vector2i, true_if_permeable: bool = false) -> bool:
	var atlas_coords: Vector2i = %GroundLayer.get_cell_atlas_coords(Vector2i(coords[0] >> 1, coords[1] >> 1))
	if atlas_coords == Vector2i(-1, -1):
		return false
	else:
		if true_if_permeable:
			return true
		else:
			var tile_data: TileData = (%GroundLayer as TileMapLayer).get_cell_tile_data(Vector2i(coords[0] >> 1, coords[1] >> 1))
			if tile_data:
				return not tile_data.get_custom_data("is_permeable")
			else:
				return true
func is_water(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i(0, 1)
func is_gas(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i(0, 2)
func is_fire(coords: Vector2i) -> bool:
	var atlas_coords = get_cell_atlas_coords(coords)
	return atlas_coords[0] == 0 and atlas_coords[1] <= 6 and atlas_coords[1] >= 3
func is_lava(coords: Vector2i) -> bool:
	var atlas_coords = get_cell_atlas_coords(coords)
	return atlas_coords[0] == 0 and atlas_coords[1] <= 10 and atlas_coords[1] >= 8
func is_sink(coords: Vector2i) -> bool:
	return get_cell_atlas_coords(coords) == Vector2i(0, 11)
func can_burn(coords: Vector2i) -> bool:
	return is_gas(coords) or is_empty(coords)
func can_explode(coords: Vector2i) -> bool:
	var atlas_coords = TileInfo.OVERLAY_LOOKUP[%GroundOverlayLayer.get_cell_atlas_coords(Vector2i(coords[0] >> 1, coords[1] >> 1))]
	return atlas_coords.name == "Ruby" or atlas_coords.name == "RubyE" or atlas_coords.name == "Emerald"

func can_be_displaced_by_water(coords: Vector2i) -> bool:
	return is_empty(coords) or is_gas(coords) or is_fire(coords) or is_sink(coords)
func can_be_displaced_by_gas(coords: Vector2i) -> bool:
	return is_empty(coords) or is_sink(coords)
func can_be_displaced_by_ground(coords: Vector2i) -> bool:
	return is_water(coords) or is_gas(coords) or is_fire(coords)

func set_empty(coords: Vector2i) -> void: # does not empty ground tile
	set_cell(coords, -1)
func set_gas(coords: Vector2i) -> void:
	set_cell(coords, 0, Vector2i(0, 2))
func set_water(coords: Vector2i) -> void:
	set_cell(coords, 0, Vector2i(0, 1))
func set_fire(coords: Vector2i, level: int = 0) -> void:
	set_cell(coords, 0, Vector2i(0, clamp(level + 3, 3, 6)))

func swap_cell(a: Vector2i, b: Vector2i) -> void:
	# if a or b is vent, remove other
	if is_sink(a):
		set_empty(b)
	elif is_sink(b):
		set_empty(a)
	else:
		var temp: Vector2i = get_cell_atlas_coords(a)
		set_cell(a, 0, get_cell_atlas_coords(b))
		set_cell(b, 0, temp)

func sort_fn_desc(a: Vector2i, b: Vector2i) -> bool:
	return a[1] > b[1]

func sort_fn_asc(a: Vector2i, b: Vector2i) -> bool:
	return a[1] < b[1]

# this maps 16x16 grid tile locations for sapphires to their bottom two 8x8 subtiles
func get_water_sources() -> Array[Vector2i]:
	var output_locs: Array[Vector2i] = []
	for loc_arr: Array[Vector2i] in [
		%GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(0, 3)),
		%GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(1, 3))
	]:
		for loc in loc_arr:
			output_locs.append(Vector2i(loc[0] * 2, loc[1] * 2 + 1))
			output_locs.append(Vector2i(loc[0] * 2 + 1, loc[1] * 2 + 1))
	return output_locs

# this maps 16x16 grid tile locations for emeralds to their top two 8x8 subtiles
func get_gas_sources() -> Array[Vector2i]:
	var output_locs: Array[Vector2i] = []
	for loc_arr: Array[Vector2i] in [
		%GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(0, 4)),
		%GroundOverlayLayer.get_used_cells_by_id(0, Vector2i(1, 4))
	]:
		for loc in loc_arr:
			output_locs.append(Vector2i(loc[0] * 2, loc[1] * 2))
			output_locs.append(Vector2i(loc[0] * 2 + 1, loc[1] * 2))
	return output_locs

func get_water_cells() -> Array[Vector2i]:
	var water_cells: Array[Vector2i] = get_used_cells_by_id(0, Vector2i(0, 1))
	return water_cells
	
func get_gas_cells() -> Array[Vector2i]:
	var gas_cells: Array[Vector2i] = get_used_cells_by_id(0, Vector2i(0, 2))
	return gas_cells
