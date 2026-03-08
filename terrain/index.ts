import { buildGrid } from "./grid";
import { tick } from "./subgrid";
import type { GridOptions, Subgrid } from "./types";
import { generateAndDisplayImage } from "./utils";

const O: GridOptions = {
  SEED: 1,
  W: 20, // 91, // 31,
  H: 80, // 400,
  CHUTE_DEPTH: 5,
};

let grid = buildGrid(O);
let subgrid: Subgrid = [];
let last = -1;
for (let i = 0; i < 180; i++) {
  [grid, subgrid] = tick(grid, subgrid);

  const c = subgrid.reduce((a, b) => a + b.size, 0);
  if (c === last) {
    break;
  } else {
    last = c;
  }

  generateAndDisplayImage(grid, subgrid);
  await new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, 100);
  });
}
