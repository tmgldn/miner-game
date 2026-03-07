import { buildGrid } from "./grid";
import { tick } from "./subgrid";
import type { GridOptions, Subgrid } from "./types";
import { generateAndDisplayImage } from "./utils";

const O: GridOptions = {
  W: 31,
  H: 200,
  CHUTE_DEPTH: 5,
};

let grid = buildGrid(O);
let subgrid: Subgrid = [];
for (let i = 0; i < 180; i++) {
  [grid, subgrid] = tick(grid, subgrid);
}

generateAndDisplayImage(grid, subgrid);
