import type { Grid, Subgrid, GridOptions } from "../types";
import { TILES, SUBTILES } from "../constants";
import "./style.css";
import { tick } from "../cycle/cycle";
import { buildGrid } from "../generation/grid";

const SCALE_FACTOR = 1;
const O: GridOptions = {
  SEED: 1,
  W: 31,
  H: 100,
  CHUTE_DEPTH: 5,
};

const tilePx = SCALE_FACTOR * 4;
const subtilePx = SCALE_FACTOR * 2;
const halfTilePx = SCALE_FACTOR * 2;

document.querySelector<HTMLDivElement>("#app")!.innerHTML = `
  <div id="canvas-container">
    <canvas id="layer-0" width="${O.W * 4}" height="${O.H * 4}"></canvas>
    <canvas id="layer-1" width="${O.W * 4}" height="${O.H * 4}"></canvas>
  </div>
`;

const backgroundCanvas = document.querySelector<HTMLCanvasElement>("#layer-0")!;
const backgroundCtx = backgroundCanvas.getContext("2d")!;

const foregroundCanvas = document.querySelector<HTMLCanvasElement>("#layer-1")!;
const foregroundCtx = foregroundCanvas.getContext("2d")!;

const player = {
  x: 60,
  y: 20,
  width: 4,
  height: 4,
  speed: 2,
};

const keys: { [key: string]: boolean } = Object.create(null);
window.addEventListener("keydown", (e) => {
  keys[e.key] = true;
  e.stopPropagation();
  e.preventDefault();
  return false;
});
window.addEventListener("keyup", (e) => {
  keys[e.key] = false;
  e.stopPropagation();
  e.preventDefault();
  return false;
});

function drawGrid(ctx: CanvasRenderingContext2D, grid: Grid) {
  for (let i = 0; i < grid.length; i++) {
    for (let j = 0; j < grid[i].length; j++) {
      const tileId = grid[i][j];
      const tile = TILES[tileId];

      if (tileId === "?") {
        ctx.fillStyle = "#666";
        ctx.fillRect(j * tilePx, i * tilePx, tilePx, tilePx);

        ctx.fillStyle = "#888";
        ctx.fillRect(j * tilePx, i * tilePx, halfTilePx, halfTilePx);

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
}

function drawSubgrid(ctx: CanvasRenderingContext2D, subgrid: Subgrid) {
  for (let i = 0; i < subgrid.length; i++) {
    for (const [j, subtileId] of subgrid[i].entries()) {
      if (subtileId !== undefined) {
        const subtile = SUBTILES[subtileId];
        ctx.fillStyle = subtile.colour;
        ctx.fillRect(j * subtilePx, i * subtilePx, subtilePx, subtilePx);
      }
    }
  }
}

function drawPlayer(ctx: CanvasRenderingContext2D) {
  // ctx.fillStyle = "#f00";
  // ctx.fillRect(player.x, player.y, player.width, player.height);

  ctx.fillStyle = "#f006";
  const cx = player.x + halfTilePx;
  const cy = player.y + halfTilePx;

  const x_ = cx - (cx % tilePx);
  const y_ = cy - (cy % tilePx);

  ctx.fillRect(x_ - 1, y_ - 1, tilePx + 2, 1);
  ctx.fillRect(x_ - 1, y_ + tilePx, tilePx + 2, 1);
  ctx.fillRect(x_ - 1, y_, 1, tilePx);
  ctx.fillRect(x_ + tilePx, y_, 1, tilePx);
}

let grid = buildGrid(O);
let subgrid: Subgrid = new Array(O.H * 2)
  .fill(0)
  .map(() => new Array(O.W).fill(undefined));

function update() {
  if (keys["ArrowRight"]) player.x += player.speed;
  if (keys["ArrowLeft"]) player.x -= player.speed;
  if (keys["ArrowUp"]) player.y -= player.speed;
  if (keys["ArrowDown"]) player.y += player.speed;
  if (keys[" "]) {
    const i = Math.floor((player.y + halfTilePx) / tilePx);
    const j = Math.floor((player.x + halfTilePx) / tilePx);

    if (i >= 0 && i < grid.length - 1 && j > 0 && j < grid[0].length - 1) {
      if (grid[i][j] !== "|") {
        grid[i][j] = " ";
      }
    }
  }

  player.x = Math.max(
    0,
    Math.min(foregroundCanvas.width - player.width, player.x),
  );
  player.y = Math.max(
    0,
    Math.min(foregroundCanvas.height - player.height, player.y),
  );

  [grid, subgrid] = tick(O, grid, subgrid);
}
function render() {
  foregroundCtx.clearRect(
    0,
    0,
    foregroundCanvas.width,
    foregroundCanvas.height,
  );
  backgroundCtx.clearRect(
    0,
    0,
    backgroundCanvas.width,
    backgroundCanvas.height,
  );

  drawGrid(foregroundCtx, grid);
  drawSubgrid(backgroundCtx, subgrid);
  drawPlayer(foregroundCtx);
}
let i = 0;
function gameLoop() {
  if (++i % 5 === 0) update();
  render();
  requestAnimationFrame(gameLoop);
}

// Start the game loop
gameLoop();
