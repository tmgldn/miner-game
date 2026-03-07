import { createNoiseGrid } from "./noiseGrid";
import type { GridOptions, Grid } from "./types";

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
  grid[O.H - 2][centreIdx] = "£";

  return grid;
}
