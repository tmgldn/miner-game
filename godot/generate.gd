extends Node

enum TileId {
	Soil,
	Bronze,
	Silver,
	Gold,
	Sapphire,
	Emerald,
	Diamond,
	SilverInRock,
	GoldInRock,
	SapphireInRock,
	EmeraldInRock,
	DiamondInRock,
	# not generated
	Undef,
	Empty,
	Boundary,
	Boulder,
}

const ORE_LIST = [
	TileId.Soil,
	TileId.Bronze,
	TileId.SilverInRock,
	TileId.Silver,
	TileId.GoldInRock,
	TileId.Sapphire,
	TileId.Gold,
	TileId.SapphireInRock,
	TileId.DiamondInRock,
	TileId.Emerald,
	TileId.EmeraldInRock,
	TileId.DiamondInRock,
	TileId.SapphireInRock,
	TileId.Gold,
	TileId.Diamond,
	TileId.EmeraldInRock,
	TileId.DiamondInRock
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

	var layerCount = ORE_LIST.size() - 4
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
			var tile_id: TileId = TileId.Soil

			if n < -0.22:
				tile_id = TileId.Empty
			elif n < -0.13 or n > 0.45:
				var rng_val = rng.randf()
				if rng_val < 0.45:
					var offset = int(floor(i * layerCount / float(H)))
					var layerStart = offset * tilesPerLayer
					var exponentModifier = (0.5 * (i - layerStart)) / tilesPerLayer
					var r = int(floor(pow(rng.randf(), 1.25 - exponentModifier) * 5))
					tile_id = ORE_LIST[offset + r]
					if n > 0.45 and (tile_id == TileId.Sapphire or tile_id == TileId.SapphireInRock):
						tile_id = TileId.EmeraldInRock
				elif rng_val > 0.7:
					tile_id = TileId.Boulder

			noiseData[i][j] = tile_id

	return noiseData


## Builds the complete grid including the chute, cone, walls and bottom.
func build_grid(SEED: int) -> Array[Array]:
	var centreIdx = W / 2  # integer division (floor)
	var wallEndIdx = 0
	var grid = create_noise_grid(SEED)

	# -------- cone (top) --------
	var max_i = W / 4  # integer division
	for i in range(max_i):
		var outer = 1 + 2 * i
		var inner = 1 + 2 * (i + 1)
		for j in W:
			if abs(j - centreIdx) >= outer:
				if abs(j - centreIdx) >= inner:
					grid[i][j] = TileId.Boundary
				else:
					grid[i][j] = TileId.Boundary
					wallEndIdx = i

	# -------- chute --------
	grid[0][centreIdx] = TileId.Empty
	for i in range(1, CHUTE_DEPTH):
		grid[i][centreIdx - 1] = TileId.Boulder
		grid[i][centreIdx] = TileId.Empty
		grid[i][centreIdx + 1] = TileId.Boulder
	
	# 3x3 fixed shape at base of chute
	grid[CHUTE_DEPTH][centreIdx - 1] = TileId.Empty
	grid[CHUTE_DEPTH][centreIdx] = TileId.Empty
	grid[CHUTE_DEPTH][centreIdx + 1] = TileId.Empty
	grid[CHUTE_DEPTH + 1][centreIdx - 1] = TileId.Empty
	grid[CHUTE_DEPTH + 1][centreIdx] = TileId.Boundary
	grid[CHUTE_DEPTH + 1][centreIdx + 1] = TileId.Empty
	grid[CHUTE_DEPTH + 2][centreIdx - 1] = TileId.Empty
	grid[CHUTE_DEPTH + 2][centreIdx] = TileId.Empty
	grid[CHUTE_DEPTH + 2][centreIdx + 1] = TileId.Empty

	# -------- side walls --------
	for i in range(wallEndIdx, H):
		grid[i][0] = TileId.Boundary
		grid[i][W - 1] = TileId.Boundary

	# -------- bottom wall --------
	for i in W:
		grid[H - 1][i] = TileId.Boundary

	return grid


var TILES: Dictionary[TileId, Dictionary] = {
	TileId.Soil: { g = Vector2(1, 0), o = null },
	TileId.Bronze: { g = Vector2(1, 0), o = Vector2(0, 3) },
	TileId.Silver: { g = Vector2(1, 0), o = Vector2(1, 3) },
	TileId.Gold: { g = Vector2(1, 0), o = Vector2(2, 3) },
	TileId.Sapphire: { g = Vector2(1, 0), o = Vector2(3, 3) },
	TileId.Emerald: { g = Vector2(1, 0), o = Vector2(4, 3) },
	TileId.Diamond: { g = Vector2(1, 0), o = Vector2(6, 3) },
	TileId.SilverInRock: { g = Vector2(4, 0), o = Vector2(1, 3) },
	TileId.GoldInRock: { g = Vector2(4, 0), o = Vector2(2, 3) },
	TileId.SapphireInRock: { g = Vector2(4, 0), o = Vector2(3, 3) },
	TileId.EmeraldInRock: { g = Vector2(4, 0), o = Vector2(4, 3) },
	TileId.DiamondInRock: { g = Vector2(4, 0), o = Vector2(6, 3) },
	# not generated
	TileId.Undef: { g = null, o = null },
	TileId.Empty: { g = null, o = null },
	TileId.Boundary: { g = Vector2(0, 1), o = null },
	TileId.Boulder: { g = Vector2(4, 0), o = null },
}

func set_tiles_from_grid(grid):
	for i in H:
		var row: Array = grid[i]
		for j in W:
			var cell: TileId = row[j]
			if cell == TileId.Boundary:
				continue
			if cell == TileId.Undef:
				%Ground.set_cell(Vector2(j, i), 0, Vector2(-1, -1))
			
			var dict: Dictionary = TILES[cell]
			if dict.g == null:
				%Ground.set_cell(Vector2(j, i), -1)
			else:
				%Ground.set_cell(
					Vector2(j, i),
					0,
					dict.g
				)
			if dict.o == null:
				%GroundOverlay.set_cell(Vector2(j, i), -1)
			else:
				%GroundOverlay.set_cell(
					Vector2(j, i),
					0,
					dict.o
				)
