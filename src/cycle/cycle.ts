import type { Grid, SubtileID, Subgrid, GridOptions } from "../types";

type ParticleConfig = {
  id: SubtileID;
  moveDir: number; // +1 for down, -1 for up
  canReplace: Record<SubtileID | " " | "*", 0 | 1 | -1>;
};
type ParticleConfigs = Record<SubtileID, ParticleConfig>;

const PARTICLE_CONFIGS: ParticleConfigs = {
  ".W": {
    id: ".W",
    moveDir: 1,
    canReplace: { ".W": 0, ".G": -1, " ": 1, "*": 0 },
  },
  ".G": {
    id: ".G",
    moveDir: -1,
    canReplace: { ".W": -1, ".G": 0, " ": 1, "*": 0 },
  },
};

export function tick(
  o: GridOptions,
  grid: Grid,
  subgrid: Subgrid,
): [Grid, Subgrid] {
  const H = o.H * 2;
  const W = o.W * 2;

  const old = subgrid;
  const next: Subgrid = new Array(H)
    .fill(0)
    .map(() => new Array(W).fill(undefined));

  const at = (i: number, j: number): SubtileID | " " | "*" => {
    if (i < 0 || j < 0 || i >= H || j >= W) return "*";
    return old[i][j] || (grid[i >> 1][j >> 1] === " " ? " " : "*");
  };

  // spawn sources
  for (let i = 0; i < grid.length; i++) {
    for (let j = 0; j < grid[i].length; j++) {
      if (grid[i][j] === "W" || grid[i][j] === "w") {
        next[i * 2 + 1][j * 2] = ".W";
        next[i * 2 + 1][j * 2 + 1] = ".W";
      }
      if (grid[i][j] === "E" || grid[i][j] === "e") {
        next[i * 2][j * 2] = ".G";
        next[i * 2][j * 2 + 1] = ".G";
      }
    }
  }

  const canMoveTo = (from: SubtileID, to: ReturnType<typeof at>): number => {
    return PARTICLE_CONFIGS[from].canReplace[to];
  };

  const tryMoveTo = (
    fromI: number,
    fromJ: number,
    toI: number,
    tiJ: number,
    particle: ParticleConfig,
  ) => {
    const prev = at(toI, tiJ);

    const move = canMoveTo(particle.id, prev);
    if (move) {
      if (move === -1) {
        next[toI][tiJ] = particle.id;
        next[fromI][fromJ] = prev as SubtileID;
      } else if (Math.random() > 0.5) {
        next[toI][tiJ] = particle.id;
      } else {
        next[fromI][fromJ] = particle.id;
      }
      return true;
    }
    return false;
  };

  for (let i = H - 2; i > 0; i--) {
    const dir = Math.random() < 0.5 ? 1 : -1;

    for (
      let j = dir === 1 ? 1 : W - 2;
      dir === 1 ? j < W - 1 : j > 0;
      j += dir
    ) {
      const id = old[i][j];
      if (!id) continue;

      const particle = PARTICLE_CONFIGS[id];
      if (!particle) continue;

      // forward
      if (tryMoveTo(i, j, i + particle.moveDir, j, particle)) continue;

      // diagonals
      if (tryMoveTo(i, j, i + particle.moveDir, j - 1, particle)) continue;
      if (tryMoveTo(i, j, i + particle.moveDir, j + 1, particle)) continue;

      // sideways pressure
      const ml = at(i, j - 1);
      const mr = at(i, j + 1);

      let dj = 0;
      const pressureL =
        (at(i - particle.moveDir, j - 1) === id ? 3 : 0) + (ml === id ? 1 : 0);
      const pressureR =
        (at(i - particle.moveDir, j + 1) === id ? 3 : 0) + (mr === id ? 1 : 0);

      if (canMoveTo(id, ml) && !canMoveTo(id, mr)) dj = -1;
      else if (!canMoveTo(id, ml) && canMoveTo(id, mr)) dj = 1;
      else if (canMoveTo(id, ml) && canMoveTo(id, mr)) {
        if (pressureL < pressureR) dj = -1;
        else if (pressureR < pressureL) dj = 1;
        else dj = Math.random() < 0.5 ? 1 : -1;
      }

      if (dj !== 0 && tryMoveTo(i, j, i, j + dj, particle)) continue;

      if (!next[i][j]) next[i][j] = id;
    }
  }

  // prevents 01->10->01 inf loop
  for (let i = 0; i < next.length; i++) {
    for (let j = 0; j < next[i].length - 1; j += 2) {
      const a = subgrid[i][j];
      const b = subgrid[i][j + 1];
      const c = next[i][j];
      const d = next[i][j + 1];

      if ((a === ".W" && b !== ".W") || (a !== ".W" && b === ".W")) {
        if (c === ".W" || (d === ".W" && Math.random() > 0.99)) {
          next[i][j] = ".W";
          next[i][j + 1] = ".W";
        }
      }
      if ((a === ".G" && b === undefined) || (a === undefined && b === ".G")) {
        if (
          (c === ".G" && d === undefined) ||
          (c === undefined && d === ".G" && Math.random() > 0.99)
        ) {
          next[i][j] = ".G";
          next[i][j + 1] = ".G";
        }
      }

      if (i) {
        const tl = subgrid[i - 1][j];
        const bl = subgrid[i][j];
        if (tl === ".W" && bl === ".G") {
          subgrid[i - 1][j] = bl;
          subgrid[i][j] = tl;
        }
        const tr = subgrid[i - 1][j + 1];
        const br = subgrid[i][j + 1];
        if (tr === ".W" && br === ".G") {
          subgrid[i - 1][j + 1] = br;
          subgrid[i][j + 1] = tr;
        }
      }
    }
  }

  return [grid, next];
}
