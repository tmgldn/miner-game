import { createNoiseGrid } from "./noiseGrid";
import type { GridOptions, Grid, SubtileID, Subgrid } from "./types";

const precedence: Record<SubtileID, Record<SubtileID | " " | "*", 0 | 1>> = {
  ".W": {
    " ": 1,
    "*": 0,
    ".W": 0,
    ".G": 1,
  },
  ".G": {
    " ": 1,
    "*": 0,
    ".W": 0,
    ".G": 0,
  },
} as const;

const toCheck: Record<SubtileID, [number, number][]> = {
  ".W": [
    [1, 0],
    [1, -1],
    [1, 1],
    [0, -1],
    [0, 1],
  ],
  ".G": [
    [-1, 0],
    [-1, -1],
    [-1, 1],
    [0, -1],
    [0, 1],
  ],
} as const;

function increment(
  id: SubtileID,
  grid: Grid,
  prev: Subgrid,
  next: Subgrid,
  i: number,
  j: number,
): void {
  const W_ = grid[0].length * 4;
  const canReplaceLookup = precedence[id];
  for (let [di, dj] of toCheck[id]) {
    const subgridRow = prev[i + di];
    if (subgridRow) {
      const j_ = j + dj;
      if (j_ < 0 || j_ >= W_) {
        continue;
      }

      const sp = subgridRow.get(j + dj);
      if (sp) {
        if (canReplaceLookup[sp]) {
          next[i + di].set(j + dj, id);
          break;
        }
      } else {
        const gI = ~~((i + di) * 0.25001);
        const p = grid[gI][~~((j + dj) * 0.25001)];
        const k = p === " " ? " " : "*";
        if (canReplaceLookup[k]) {
          next[i + di].set(j + dj, id);
          break;
        }
      }
    }
  }
  const p = grid[~~(i * 0.25001)][~~(j * 0.25001)];
  if (p) next[i].set(j, id);
}

// used to represent fluid (water, gas, lava) dynamics
export function tick(grid: Grid, subgrid: Subgrid): [Grid, Subgrid] {
  const newSubgrid: Subgrid = new Array(
    grid.length + grid.length + grid.length + grid.length,
  )
    .fill(0)
    .map(() => new Map<number, SubtileID>());

  for (let i = 0; i < subgrid.length; i++) {
    const row = subgrid[i];
    if (row.size) {
      for (const [j, id] of row) {
        if (id === ".W" || id === ".G") {
          increment(id, grid, subgrid, newSubgrid, i, j);
        }
      }
    }
  }

  for (let i = 0; i < grid.length; i++) {
    const row = grid[i];
    for (let j = 0; j < row.length; j++) {
      if (row[j] === "W" || row[j] === "w") {
        for (let k = 0; k < 4; k++) {
          increment(
            ".W",
            grid,
            subgrid,
            newSubgrid,
            i + i + i + i + 3,
            j + j + j + j + k,
          );
          newSubgrid[i + i + i + i + 3].delete(j + j + j + j + k);
        }
      }
      if (row[j] === "E" || row[j] === "e") {
        for (let k = 0; k < 4; k++) {
          increment(
            ".G",
            grid,
            subgrid,
            newSubgrid,
            i + i + i + i,
            j + j + j + j + k,
          );
          newSubgrid[i + i + i + i].delete(j + j + j + j + k);
        }
      }
    }
  }

  return [grid, newSubgrid];
}
