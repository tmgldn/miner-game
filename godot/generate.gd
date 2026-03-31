extends Node

const ORE_SETS: Array[Array] = [
	[
		G.TileId.Iron,
		G.TileId.IronInRock,
		G.TileId.SilverInRock,
		G.TileId.Silver,
	],
	[
		G.TileId.SilverInRock,
		G.TileId.Silver,
		G.TileId.GoldInRock,
		G.TileId.Gold,
	],
	[
		G.TileId.GoldInRock,
		G.TileId.Gold,
		G.TileId.SapphireInRock,
		G.TileId.Sapphire,
	],
	[
		G.TileId.SapphireInRock,
		G.TileId.Sapphire,
		G.TileId.EmeraldInRock,
		G.TileId.Emerald,
	],
	[
		G.TileId.EmeraldInRock,
		G.TileId.Emerald,
		G.TileId.RubyInRock,
		G.TileId.Ruby,
	],
	[
		G.TileId.RubyInRock,
		G.TileId.Ruby,
		G.TileId.DiamondInRock,
		G.TileId.Diamond,
	],
]

const W = 31
const H = 200
const CHUTE_DEPTH = 4

## Creates a noise‑based grid of tile IDs.
func create_noise_grid(SEED: int) -> Array[Array]:
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
			var tile_id: G.TileId = G.TileId.Soil

			if n < -0.22:
				tile_id = G.TileId.Empty
			elif n < -0.13 or n > 0.4:
				var rng_val = rng.randf()
				if rng_val < 0.4:
					var offset = int(floor(i * layerCount / float(H)))
					var layerStart = offset * tilesPerLayer
					var exponentModifier = (0.5 * (i - layerStart)) / tilesPerLayer
					var r = int(floor(pow(rng.randf(), 1.25 - exponentModifier) * 4))
					tile_id = ORE_SETS[offset][r]
				elif rng_val > 0.6:
					tile_id = G.TileId.Rock

			noiseData[i][j] = tile_id

	return noiseData


## Builds the complete grid including the chute, cone, walls and bottom.
func build_grid(SEED: int) -> Array[Array]:
	var centreIdx = W / 2 # integer division (floor)
	var wallEndIdx = 0
	var grid = create_noise_grid(SEED)

	# -------- cone (top) --------
	var max_i = W / 4 # integer division
	for i in range(max_i):
		var outer = 1 + 2 * i
		var inner = 2 + 2 * (i + 1)
		for j in W:
			if abs(j - centreIdx) >= outer:
				if abs(j - centreIdx) >= inner:
					grid[i][j] = G.TileId.Empty
				else:
					grid[i][j] = G.TileId.Boundary
					wallEndIdx = i

	# -------- chute --------
	grid[0][centreIdx] = G.TileId.Empty
	for i in range(1, CHUTE_DEPTH + 4):
		grid[i][centreIdx - 2] = G.TileId.Soil
		grid[i][centreIdx - 1] = G.TileId.Soil
		grid[i][centreIdx] = G.TileId.Empty
		grid[i][centreIdx + 1] = G.TileId.Soil
		grid[i][centreIdx + 2] = G.TileId.Soil
		if i > 1:
			grid[i][centreIdx - 4] = G.TileId.Iron if SEED % 2 else G.TileId.IronInRock
			grid[i][centreIdx - 3] = G.TileId.Soil
			grid[i][centreIdx + 3] = G.TileId.Soil
			grid[i][centreIdx + 4] = G.TileId.IronInRock if SEED % 2 else G.TileId.Iron
		if i > 2:
			grid[i][centreIdx - 5] = G.TileId.Soil
			grid[i][centreIdx + 5] = G.TileId.Soil
	
	# fixed layout at base of chute - bear easter egg :)
	grid[CHUTE_DEPTH - 1][centreIdx - 2] = G.TileId.Boundary
	grid[CHUTE_DEPTH - 1][centreIdx + 2] = G.TileId.Boundary
	
	grid[CHUTE_DEPTH][centreIdx - 1] = G.TileId.Empty
	grid[CHUTE_DEPTH][centreIdx] = G.TileId.Boundary
	grid[CHUTE_DEPTH][centreIdx + 1] = G.TileId.Empty
	
	grid[CHUTE_DEPTH + 1][centreIdx - 3] = G.TileId.Iron if SEED % 2 else G.TileId.IronInRock
	grid[CHUTE_DEPTH + 1][centreIdx - 2] = G.TileId.Soil
	grid[CHUTE_DEPTH + 1][centreIdx - 1] = G.TileId.Empty
	grid[CHUTE_DEPTH + 1][centreIdx] = G.TileId.Empty
	grid[CHUTE_DEPTH + 1][centreIdx + 1] = G.TileId.Empty
	grid[CHUTE_DEPTH + 1][centreIdx + 2] = G.TileId.Soil
	grid[CHUTE_DEPTH + 1][centreIdx + 3] = G.TileId.IronInRock if SEED % 2 else G.TileId.Iron
	
	grid[CHUTE_DEPTH + 2][centreIdx - 5] = G.TileId.Soil
	grid[CHUTE_DEPTH + 2][centreIdx - 4] = G.TileId.Soil
	grid[CHUTE_DEPTH + 2][centreIdx - 3] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx - 2] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx - 1] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx + 1] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx + 2] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx + 3] = G.TileId.Iron
	grid[CHUTE_DEPTH + 2][centreIdx + 4] = G.TileId.Soil
	grid[CHUTE_DEPTH + 2][centreIdx + 5] = G.TileId.Soil
	
	grid[CHUTE_DEPTH + 3][centreIdx - 5] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx - 4] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx - 3] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx - 2] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx - 1] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx + 1] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx + 2] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx + 3] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx + 4] = G.TileId.Soil
	grid[CHUTE_DEPTH + 3][centreIdx + 5] = G.TileId.Soil
	
	grid[CHUTE_DEPTH + 3][centreIdx] = G.TileId.Soil

	# -------- side walls --------
	for i in range(wallEndIdx, H):
		grid[i][0] = G.TileId.Boundary
		grid[i][W - 1] = G.TileId.Boundary

	# -------- bottom wall --------
	for i in W:
		grid[H - 1][i] = G.TileId.Boundary

	return grid


func set_tiles_from_grid(grid):
	for i in H:
		var row: Array = grid[i]
		for j in W:
			var cell: G.TileId = row[j]
			var dict: Dictionary = G.TILE_DATA[cell]
			if dict.g == Vector2i(-1, -1):
				%Ground.set_cell(Vector2i(j, i), -1)
			else:
				%Ground.set_cell(
					Vector2i(j, i),
					0,
					dict.g
				)
			if dict.o == Vector2i(-1, -1):
				%GroundOverlay.set_cell(Vector2i(j, i), -1)
			else:
				%GroundOverlay.set_cell(
					Vector2i(j, i),
					0,
					dict.o
				)
