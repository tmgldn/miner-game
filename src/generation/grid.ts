import { MersenneTwister } from "../_lib/twister";
import type { GridOptions, Grid, TileID } from "../types";
import FastNoiseLite from "fastnoise-lite";

const ORE_LIST: TileID[] = [
  "#",
  "b",
  "S",
  "s",
  "G",
  "w",
  "g",
  "W",
  "D",
  "e",
  "E",
  "D",
  "W",
  "g",
  "d",
  "E",
  "D",
];

/**
 * build random grid
 */
function createNoiseGrid({ H, W, SEED }: GridOptions): Grid {
  const noise = new FastNoiseLite(SEED);
  const Pseudo = new MersenneTwister(SEED);

  const layerCount = ORE_LIST.length - 4;
  const tilesPerLayer = H / layerCount;

  noise.SetNoiseType(FastNoiseLite.NoiseType.OpenSimplex2S);
  noise.SetFrequency(0.1);
  noise.SetFractalType("FBm");
  noise.SetFractalOctaves(2);
  noise.SetFractalLacunarity(2.0);
  noise.SetFractalGain(0.5);
  noise.SetFractalWeightedStrength(0.0);

  const noiseData: TileID[][] = [];
  for (let i = 0; i < H; i++) {
    const x3 = i + i + i;
    noiseData[i] = [];
    for (let j = 0; j < W; j++) {
      const n =
        (noise.GetNoise(x3, j) +
          noise.GetNoise(x3 + 1, j) +
          noise.GetNoise(x3 + 2, j)) /
        3;
      let tile: TileID = "#";
      if (n < -0.22) {
        tile = " ";
      } else if (n < -0.13 || n > 0.45) {
        const rng = Pseudo.random();
        if (rng < 0.45) {
          const offset = Math.floor((i * layerCount) / H);
          const layerStart = offset * tilesPerLayer;
          let exponentModifier = (0.5 * (i - layerStart)) / tilesPerLayer;

          const r = Math.floor(
            Pseudo.random() ** (1.25 - exponentModifier) * 5,
          );
          tile = ORE_LIST[offset + r];
          if (n > 0.45 && (tile === "w" || tile === "W")) {
            tile = "G";
          }
        } else if (rng > 0.7) {
          tile = "@";
        }
      }

      noiseData[i][j] = tile;
    }
  }

  return noiseData;
}

/**
 * build whole grid (including random part within)
 */
export function buildGrid(O: GridOptions) {
  const centreIdx = Math.floor(O.W / 2);

  let wallEndIdx = 0;

  const grid: Grid = createNoiseGrid(O);

  // chute
  grid[0][centreIdx] = "!";
  for (let i = 1; i < O.CHUTE_DEPTH; i++) {
    grid[i][centreIdx - 1] = "@";
    grid[i][centreIdx] = " ";
    grid[i][centreIdx + 1] = "@";
  }
  grid[O.CHUTE_DEPTH][centreIdx] = " ";
  for (let i = 0; i < 2; i++) {
    for (let j = 1; j < 4; j++) {
      grid[O.CHUTE_DEPTH + i][centreIdx + j] = "#";
      grid[O.CHUTE_DEPTH + i][centreIdx - j] = "#";
    }
  }
  grid[O.CHUTE_DEPTH + 1][centreIdx] = "@";

  // cone
  for (let i = 0; i < O.W / 4; i++) {
    for (let j = 0; j < O.W; j++) {
      if (Math.abs(j - centreIdx) >= 1 + i + i) {
        if (Math.abs(j - centreIdx) >= 1 + (i + 1) + (i + 1)) {
          grid[i][j] = "!";
        } else {
          grid[i][j] = "|";
          wallEndIdx = i;
        }
      }
    }
  }

  // sides
  for (let i = wallEndIdx; i < O.H; i++) {
    grid[i][0] = "|";
    grid[i][O.W - 1] = "|";
  }

  // bottom cone
  for (let i = 0; i < O.W / 4; i++) {
    for (let j = 0; j < O.W; j++) {
      if (Math.abs(j - centreIdx) >= 1 + i + i) {
        if (Math.abs(j - centreIdx) >= 1 + (i + 1) + (i + 1)) {
          grid[O.H - 2 - i][j] = "|";
        } else {
          grid[O.H - 2 - i][j] = "|";
          wallEndIdx = i;
        }
      }
    }
  }

  // bottom
  for (let i = 0; i < O.W; i++) {
    grid[O.H - 1][i] = "|";
  }
  grid[O.H - 4][centreIdx] = "|";

  return grid;
}
