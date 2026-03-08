import { createCanvas } from "canvas";
import { terminalKittyImage } from "term-kitty-img";
import type { Grid, Subgrid, SubtileID, TileID, TileMetadata } from "./types";
import fs from "node:fs";

const TILES: Record<TileID, TileMetadata> = {
  "?": { colour: "" },
  "!": { colour: "rgb(71, 98, 101)" },
  "-": { colour: "hsl(19, 100%, 50%)" },
  "|": { colour: "hsl(300, 100%, 27%)" },
  " ": { colour: "hsl(0, 0%, 0%)" },
  "#": { colour: "hsl(30, 78%, 18%)" },
  "£": { colour: "hsl(325, 100%, 50%)" },
  "@": { colour: "hsl(30, 2%, 23%)" },
  b: { colour: "hsl(30, 100%, 33%)" },
  s: { colour: "hsl(0, 0%, 72%)" },
  g: { colour: "hsl(45, 100%, 50%)" },
  w: { colour: "hsl(189, 100%, 50%)" },
  e: { colour: "hsl(108, 99%, 37%)" },
  d: { colour: "hsl(0, 0%, 100%)" },
  S: { colour: "hsl(0, 0%, 52%)" },
  G: { colour: "hsl(45, 100%, 30%)" },
  W: { colour: "hsl(189, 100%, 30%)" },
  E: { colour: "hsl(108, 99%, 17%)" },
  D: { colour: "hsl(0, 0%, 70%)" },
};

const SUBTILES: Record<SubtileID, { colour: string }> = {
  ".W": { colour: "hsl(189, 100%, 15%)" },
  ".G": { colour: "hsl(108, 100%, 10%)" },
};

const SCALE_FACTOR = 4;

export function generateAndDisplayImage(grid: Grid, subgrid: Subgrid): void {
  const tilePx = SCALE_FACTOR + SCALE_FACTOR + SCALE_FACTOR + SCALE_FACTOR;
  const subtilePx = SCALE_FACTOR;
  const halfTilePx = SCALE_FACTOR + SCALE_FACTOR;

  const w = (grid[0].length + 1) * tilePx;
  const h = (grid.length + 1) * tilePx;
  const canvas = createCanvas(w, h);
  const ctx = canvas.getContext("2d");

  ctx.fillStyle = `rgb(91, 109, 13)`;
  ctx.fillRect(0, 0, w, h);

  for (let i = 0; i < grid.length; i++) {
    for (let j = 0; j < grid[i].length; j++) {
      const tileId = grid[i][j];
      const tile = TILES[tileId];
      if (tileId === "?") {
        ctx.fillStyle = "#666";
        ctx.fillRect(
          j * tilePx + halfTilePx,
          i * tilePx + halfTilePx,
          tilePx,
          tilePx,
        );
        ctx.fillStyle = "#tilePxtilePxtilePx";
        ctx.fillRect(
          j * tilePx + halfTilePx,
          i * tilePx + halfTilePx,
          halfTilePx,
          halfTilePx,
        );
        ctx.fillRect(
          j * tilePx + halfTilePx + halfTilePx,
          i * tilePx + tilePx,
          halfTilePx,
          halfTilePx,
        );
      } else {
        ctx.fillStyle = tile.colour;
        ctx.fillRect(
          j * tilePx + halfTilePx,
          i * tilePx + halfTilePx,
          tilePx,
          tilePx,
        );
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
