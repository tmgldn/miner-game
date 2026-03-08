import type { TileID } from "../types";
import "./style.css";

// Set up the HTML structure with two canvases
document.querySelector<HTMLDivElement>("#app")!.innerHTML = `
  <div id="canvas-container">
    <canvas id="layer-0" width="124" height="400"></canvas>
    <canvas id="layer-1" width="124" height="400"></canvas>
  </div>
`;

// Get the canvas elements
const backgroundCanvas = document.querySelector<HTMLCanvasElement>("#layer-0")!;
const foregroundCanvas = document.querySelector<HTMLCanvasElement>("#layer-1")!;

// Get the 2d context for both canvases
const backgroundCtx = backgroundCanvas.getContext("2d")!;
const foregroundCtx = foregroundCanvas.getContext("2d")!;

const TILES: Record<TileID> = {};

// Define the player object
const player = {
  x: 4,
  y: 4,
  width: 4,
  height: 4,
  speed: 1,
};

// Handle keyboard input
const keys: { [key: string]: boolean } = {};
window.addEventListener("keydown", (e) => {
  keys[e.key] = true;
});

window.addEventListener("keyup", (e) => {
  keys[e.key] = false;
});

/**
 * Abstraction layer: paint a list of pixels on an ImageData object.
 * @param imageData - The ImageData to modify.
 * @param pixels - Array of [x, y, r, g, b, a]
 */
function paintPixels(
  imageData: ImageData,
  pixels: [i: number, j: number, r: number, g: number, b: number, a: number][],
) {
  const { width, data } = imageData;
  for (const [x, y, r, g, b, a] of pixels) {
    const index = (y * width + x) * 4;
    data[index] = r;
    data[index + 1] = g;
    data[index + 2] = b;
    data[index + 3] = a;
  }
}

/**
 * Generate a list of pixel coordinates for a rectangle.
 */
function getRectanglePixels(
  x: number,
  y: number,
  w: number,
  h: number,
): [number, number][] {
  const pixels: [number, number][] = [];
  for (let dy = 0; dy < h; dy++) {
    for (let dx = 0; dx < w; dx++) {
      pixels.push([x + dx, y + dy]);
    }
  }
  return pixels;
}

// Game update function
function update() {
  // Update player position based on keyboard input
  if (keys["ArrowRight"]) {
    player.x += player.speed;
  }
  if (keys["ArrowLeft"]) {
    player.x -= player.speed;
  }
  if (keys["ArrowUp"]) {
    player.y -= player.speed;
  }
  if (keys["ArrowDown"]) {
    player.y += player.speed;
  }

  // Optional: clamp player position to stay within canvas
  player.x = Math.max(
    0,
    Math.min(foregroundCanvas.width - player.width, player.x),
  );
  player.y = Math.max(
    0,
    Math.min(foregroundCanvas.height - player.height, player.y),
  );

  // --- Background layer (unchanged) ---
  backgroundCtx.clearRect(
    0,
    0,
    backgroundCanvas.width,
    backgroundCanvas.height,
  );
  backgroundCtx.fillStyle = "blue";
  backgroundCtx.fillRect(0, 0, backgroundCanvas.width, backgroundCanvas.height);

  // --- Foreground layer using pixel abstraction ---
  // Create a new transparent ImageData for the foreground
  const imageData = foregroundCtx.createImageData(
    foregroundCanvas.width,
    foregroundCanvas.height,
  );
  const { width, data } = imageData;

  const paintTile = (i: number, j: number, tile: TileID) => {
    const index = (i * width + j) * 4;
    const [r, g, b, a] = TILES[tile];
  };

  // foregroundCtx.putImageData(imageData, 0, 0);
}

// Game loop
function gameLoop() {
  update();
  requestAnimationFrame(gameLoop);
}

// Start the game loop
gameLoop();
