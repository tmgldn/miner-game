extends Node

var GROUNDS_WITHOUT_OVERLAYS = {
	'Empty': {c = [[-1, -1]], s = 0.15, t = 'Empty'},
}

var GROUNDS_WITH_OVERLAYS = {
	'Boundary': {c = [[7, 0]], s = 0.15, t = 'Boundary'},
	'BoundaryP': {c = [[7, 1]], s = 0.15, t = 'BoundaryP'},
	# ---
	'Soil0': {c = [[0, 0], [0, 2], [0, 4]], s = 0.15, t = 'Soil1'},
	'Soil1': {c = [[1, 0], [1, 2], [1, 4]], s = 0.15, t = 'Soil2'},
	'Soil2': {c = [[2, 0], [2, 2], [2, 4]], s = 0.15, t = 'Empty'},
	'SoilF': {c = [[3, 0], [3, 2], [3, 4]], s = 0.15, t = 'Empty'},
	'Rock0': {c = [[0, 1], [0, 3], [0, 5]], s = 0.4, t = 'Rock1'},
	'Rock1': {c = [[1, 1], [1, 3], [1, 5]], s = 0.5, t = 'Rock2'},
	'Rock2': {c = [[2, 1], [2, 3], [2, 5]], s = 0.4, t = 'Rock3'},
	'Rock3': {c = [[3, 1], [3, 3], [3, 5]], s = 0.4, t = 'Rock4'},
	'Rock4': {c = [[4, 1], [4, 3], [4, 5]], s = 0.2, t = 'Empty'},
	'RockF': {c = [[5, 1], [5, 3], [5, 5]], s = 0.2, t = 'Empty'},
	# ---
	'SoilP0': {c = [[0, 0+6], [0, 2+6], [0, 4+6]], s = 0.15, t = 'SoilP1'},
	'SoilP1': {c = [[1, 0+6], [1, 2+6], [1, 4+6]], s = 0.15, t = 'SoilP2'},
	'SoilP2': {c = [[1, 0+6], [1, 2+6], [1, 4+6]], s = 0.15, t = 'Empty'},
	'SoilPF': {c = [[1, 0+6], [1, 2+6], [1, 4+6]], s = 0.15, t = 'Empty'},
	'RockP0': {c = [[0, 1+6], [0, 3+6], [0, 5+6]], s = 0.4, t = 'RockP1'},
	'RockP1': {c = [[1, 1+6], [1, 3+6], [1, 5+6]], s = 0.5, t = 'RockP2'},
	'RockP2': {c = [[2, 1+6], [2, 3+6], [2, 5+6]], s = 0.4, t = 'RockP3'},
	'RockP3': {c = [[3, 1+6], [3, 3+6], [3, 5+6]], s = 0.4, t = 'RockP4'},
	'RockP4': {c = [[4, 1+6], [4, 3+6], [4, 5+6]], s = 0.2, t = 'Empty'},
	'RockPF': {c = [[5, 1+6], [5, 3+6], [5, 5+6]], s = 0.2, t = 'Empty'},
}

var OVERLAYS = {
	'': {c = [[-1, -1]], p = 0},
	'Iron': {c = [[0, 0], [1, 0]], p = 10},
	'Silver': {c = [[0, 1], [1, 1]], p = 25},
	'Gold': {c = [[0, 2], [1, 2]], p = 50},
	'Sapphire': {c = [[0, 3], [1, 3]], p = 75},
	'Emerald': {c = [[0, 4], [1, 4]], p = 100},
	'Ruby': {c = [[0, 5], [1, 5]], p = 150},
	'Diamond': {c = [[0, 6]], p = 250},
	'RubyE': {c = [[0, 7], [1, 7]], p = 150}, # E = pending Explosion
}

var GROUND_LOOKUP: Dictionary[Vector2i, Dictionary] = {}
var OVERLAY_LOOKUP: Dictionary[Vector2i, Dictionary] = {}
var TILE_NAME_LOOKUP: Dictionary[String, Dictionary] = {}

func _ready() -> void:
	for name in GROUNDS_WITHOUT_OVERLAYS.keys():
		var ground = GROUNDS_WITHOUT_OVERLAYS[name]
		var i = 0
		var new_c = []
		for v in ground.c:
			var vec = Vector2i(v[0], v[1])
			new_c.append(vec)
			GROUND_LOOKUP[vec] = {name = name, data = ground, index = i}
			i += 1
		ground.c = new_c
	for name in GROUNDS_WITH_OVERLAYS:
		var ground = GROUNDS_WITH_OVERLAYS[name]
		var i = 0
		var new_c = []
		for v in ground.c:
			var vec = Vector2i(v[0], v[1])
			new_c.append(vec)
			GROUND_LOOKUP[vec] = {name = name, data = ground, index = i}
			i += 1
		ground.c = new_c
	for name in OVERLAYS:
		var overlay = OVERLAYS[name]
		var j = 0
		var new_c = []
		for v in overlay.c:
			var vec = Vector2i(v[0], v[1])
			new_c.append(vec)
			OVERLAY_LOOKUP[vec] = {name = name, data = overlay, index = j}
			j += 1
		overlay.c = new_c

	for g_name in GROUNDS_WITH_OVERLAYS.keys():
		for o_name in OVERLAYS.keys():
			TILE_NAME_LOOKUP[g_name + o_name] = {
				g = GROUNDS_WITH_OVERLAYS[g_name],
				o = OVERLAYS[o_name]
			}
	for g_name in GROUNDS_WITHOUT_OVERLAYS.keys():
		TILE_NAME_LOOKUP[g_name] = {g = GROUNDS_WITHOUT_OVERLAYS[g_name], o = OVERLAYS['']}

func atlas_coords_to_data(ground: Vector2i, overlay: Vector2i) -> Dictionary:
	return {gi = GROUND_LOOKUP.get(ground), oi = OVERLAY_LOOKUP.get(overlay)}
