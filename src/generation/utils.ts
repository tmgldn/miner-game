import { createCanvas } from "canvas";
import { terminalKittyImage } from "term-kitty-img";
import type { Grid, Subgrid } from "../types";
import { SUBTILES, TILES } from "../constants";
import fs from "node:fs";

const SCALE_FACTOR = 4;

export function generateAndDisplayImage(grid: Grid, subgrid: Subgrid): void {
  const tilePx = SCALE_FACTOR + SCALE_FACTOR + SCALE_FACTOR + SCALE_FACTOR;
  const subtilePx = SCALE_FACTOR;
  const halfTilePx = SCALE_FACTOR + SCALE_FACTOR;

  const w = (grid[0].length + 1) * tilePx;
  const h = (grid.length + 1) * tilePx;
  const canvas = createCanvas(w, h);
  const ctx = canvas.getContext("2d");

  for (let i = 0; i < grid.length; i++) {
    for (let j = 0; j < grid[i].length; j++) {
      const tileId = grid[i][j];
      const tile = TILES[tileId];
      if (tileId === "?") {
        // [::]
        ctx.fillStyle = "#666";
        ctx.fillRect(j * tilePx, i * tilePx, tilePx, tilePx);

        ctx.fillStyle = "#888";
        // [' ]
        ctx.fillRect(j * tilePx, i * tilePx, halfTilePx, halfTilePx);
        // [ .]
        ctx.fillRect(
          j * tilePx + halfTilePx,
          i * tilePx + halfTilePx,
          halfTilePx,
          halfTilePx,
        );
      } else {
        ctx.fillStyle = tile.colour;
        ctx.fillRect(j * tilePx, i * tilePx, tilePx, tilePx);
      }
    }
  }

  for (let i = 0; i < subgrid.length; i++) {
    for (const [j, subtileId] of subgrid[i].entries()) {
      const subtile = SUBTILES[subtileId];
      ctx.fillStyle = subtile.colour;
      ctx.fillRect(
        j * subtilePx + halfTilePx,
        i * subtilePx + halfTilePx,
        subtilePx,
        subtilePx,
      );
    }
  }

  const png = canvas.toBuffer("image/png");
  fs.writeFileSync("out.png", png);

  terminalKittyImage(canvas.toBuffer("image/png"), {
    fallback: () => {
      console.error("Could not display image");
    },
  });
}
