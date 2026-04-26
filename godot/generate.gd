extends Node

@onready var TileInfo: Node = %TileInfo

const ORE_SETS: Array[Array] = [
	[
		'Soil0Iron',
		'Rock0Iron',
		'Rock0Silver',
		'Soil0Silver',
	],
	[
		'Rock0Silver',
		'Soil0Silver',
		'Rock0Gold',
		'Soil0Gold',
	],
	[
		'Rock0Gold',
		'Soil0Gold',
		'Rock0Sapphire',
		'Soil0Sapphire',
	],
	[
		'Rock0Sapphire',
		'Soil0Sapphire',
		'Rock0Emerald',
		'Soil0Emerald',
	],
	[
		'Rock0Emerald',
		'Soil0Emerald',
		'Rock0Ruby',
		'Soil0Ruby',
	],
	[
		'Rock0Ruby',
		'Soil0Ruby',
		'Rock0Diamond',
		'Soil0Diamond',
	],
]

const W = 31
const H = 200
const CHUTE_DEPTH = 4

## Creates a noise‑based grid of tile IDs.
func create_noise_grid(SEED: int) -> void:
	var noise = FastNoiseLite.new()
	noise.seed = SEED
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.1
	noise.fractal_type = FastNoiseLite.FractalType.FRACTAL_FBM
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	noise.fractal_weighted_strength = 0.0

	var rng = RandomNumberGenerator.new()
	rng.seed = SEED

	var layerCount = len(ORE_SETS)
	var tilesPerLayer = float(H) / float(layerCount)

	var noiseData: Array[Array] = []
	noiseData.resize(H)
	for i in H:
		noiseData[i] = []
		noiseData[i].resize(W)
		var x3 = i + i + i
		for j in W:
			var n: float = (
				noise.get_noise_2d(x3, j) +
				noise.get_noise_2d(x3 + 1, j) +
				noise.get_noise_2d(x3 + 2, j)
			) / 3.0
			var tile_id: String = 'Soil0'

			if n < -0.22:
				tile_id = 'Empty'
			elif n < -0.13 or n > 0.4:
				var rng_val = rng.randf()
				if rng_val < 0.4:
					var offset = int(floor(i * layerCount / float(H)))
					var layerStart = offset * tilesPerLayer
					var exponentModifier = (0.5 * (i - layerStart)) / tilesPerLayer
					var r = int(floor(pow(rng.randf(), 1.25 - exponentModifier) * 4))
					tile_id = ORE_SETS[offset][r]
				elif rng_val > 0.6:
					tile_id = 'Rock0'

			set_cell_from_str(i, j, tile_id)

func set_cell_from_str(i: int, j: int, tile_str: String) -> void:
	var data = TileInfo.TILE_NAME_LOOKUP[tile_str]
	var ground_coords: Vector2i = data.g.c[(i + j) % len(data.g.c)]
	if ground_coords == Vector2i(-1, -1):
		%GroundLayer.set_cell(Vector2i(j, i), -1)
	else:
		%GroundLayer.set_cell(Vector2i(j, i), 0, ground_coords)
	var overlay_coords: Vector2i = data.o.c[abs(i - j) % len(data.o.c)]
	if overlay_coords == Vector2i(-1, -1):
		%GroundOverlayLayer.set_cell(Vector2i(j, i), -1)
	else:
		%GroundOverlayLayer.set_cell(Vector2i(j, i), 0, overlay_coords)

## Builds the complete grid including the chute, cone, walls and bottom.
func initialise_grid(SEED: int) -> void:
	var centreIdx = W / 2 # integer division (floor)
	var wallEndIdx = 0
	
	create_noise_grid(SEED)

	# -------- cone (top) --------
	var max_i = W / 4 # integer division
	for i in range(max_i):
		var outer = 1 + 2 * i
		var inner = 2 + 2 * (i + 1)
		for j in W:
			if abs(j - centreIdx) >= outer:
				if abs(j - centreIdx) >= inner:
					set_cell_from_str(i, j, 'Empty')
				else:
					set_cell_from_str(i, j, 'Boundary')
					wallEndIdx = i

	# -------- chute --------
	set_cell_from_str(0, centreIdx, 'Empty')
	for i in range(1, CHUTE_DEPTH + 4):
		set_cell_from_str(i, centreIdx - 2, 'Soil0')
		set_cell_from_str(i, centreIdx - 1, 'Soil0')
		set_cell_from_str(i, centreIdx, 'Empty')
		set_cell_from_str(i, centreIdx + 1, 'Soil0')
		set_cell_from_str(i, centreIdx + 2, 'Soil0')
		if i > 1:
			set_cell_from_str(i, centreIdx - 4, 'Soil0Iron' if SEED % 2 else 'Rock0Iron')
			set_cell_from_str(i, centreIdx - 3, 'Soil0')
			set_cell_from_str(i, centreIdx + 3, 'Soil0')
			set_cell_from_str(i, centreIdx + 4, 'Rock0Iron' if SEED % 2 else 'Soil0Iron')
		if i > 2:
			set_cell_from_str(i, centreIdx - 5, 'Soil0')
			set_cell_from_str(i, centreIdx + 5, 'Soil0')
	
	# fixed layout at base of chute - bear easter egg :)
	set_cell_from_str(CHUTE_DEPTH - 1, centreIdx - 2, 'Boundary')
	set_cell_from_str(CHUTE_DEPTH - 1, centreIdx + 2, 'Boundary')
	
	set_cell_from_str(CHUTE_DEPTH, centreIdx - 1, 'Empty')
	set_cell_from_str(CHUTE_DEPTH, centreIdx, 'Boundary')
	set_cell_from_str(CHUTE_DEPTH, centreIdx + 1, 'Empty')
	
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx - 3, 'Soil0Iron' if SEED % 2 else 'Rock0Iron')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx - 2, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx - 1, 'Empty')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx, 'Empty')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx + 1, 'Empty')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx + 2, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 1, centreIdx + 3, 'Rock0Iron' if SEED % 2 else 'Soil0Iron')
	
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx - 5, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx - 4, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx - 3, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx - 2, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx - 1, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx + 1, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx + 2, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx + 3, 'Soil0Iron')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx + 4, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 2, centreIdx + 5, 'Soil0')
	
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx - 5, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx - 4, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx - 3, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx - 2, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx - 1, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx + 1, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx + 2, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx + 3, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx + 4, 'Soil0')
	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx + 5, 'Soil0')

	set_cell_from_str(CHUTE_DEPTH + 3, centreIdx, 'Soil0')

	# -------- side walls --------
	for i in range(wallEndIdx, H):
		set_cell_from_str(i, 0, 'Boundary')
		set_cell_from_str(i, W - 1, 'Boundary')

	# -------- bottom wall --------
	for i in W:
		set_cell_from_str(H - 1, i, 'Boundary')
