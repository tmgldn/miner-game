extends Node

var GROUNDS_WITHOUT_OVERLAYS = {
	'Empty': {c = [[-1, -1]], s = 0.15, t = 'Empty'},
	'Boundary': {c = [[0, 0]], s = 0.15, t = 'Boundary'},
}

var GROUNDS_WITH_OVERLAYS = {
	'Soil0': {c = [[0, 1]], s = 0.15, t = 'Soil1'},
	'Soil1': {c = [[1, 1]], s = 0.15, t = 'Soil2'},
	'Soil2': {c = [[2, 1]], s = 0.15, t = 'Empty'},
	'SoilF': {c = [[3, 1]], s = 0.15, t = 'Empty'},
	'Rock0': {c = [[0, 2]], s = 0.4, t = 'Rock1'},
	'Rock1': {c = [[1, 2]], s = 0.5, t = 'Rock2'},
	'Rock2': {c = [[2, 2]], s = 0.4, t = 'Rock3'},
	'Rock3': {c = [[3, 2]], s = 0.2, t = 'Empty'},
	'RockF': {c = [[4, 2]], s = 0.2, t = 'Empty'},
}

var OVERLAYS = {
	'': {c = [[-1, -1]], p = 0},
	'Iron': {c = [[0, 3]], p = 10},
	'Silver': {c = [[0, 4]], p = 25},
	'Gold': {c = [[0, 5]], p = 50},
	'Sapphire': {c = [[0, 6]], p = 75},
	'Emerald': {c = [[0, 7]], p = 100},
	'Ruby': {c = [[0, 8]], p = 150},
	'Diamond': {c = [[0, 9]], p = 250},
	'RubyE': {c = [[0, 10]], p = 150}, # E = pending Explosion
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
	return {gi = GROUND_LOOKUP[ground], oi = OVERLAY_LOOKUP[overlay]}
