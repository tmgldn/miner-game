import type { SubtileID, TileID, TileMetadata } from "./types";

export const TILES: Record<TileID, TileMetadata> = {
  "?": { colour: "" },
  "!": { colour: "rgb(71, 98, 101)" },
  "-": { colour: "hsl(19, 100%, 50%)" },
  "|": { colour: "hsl(300, 100%, 27%)" },
  " ": { colour: "#0000" /* "hsl(0, 0%, 0%)" */ },
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

export const SUBTILES: Record<SubtileID, { colour: string }> = {
  ".W": { colour: "hsl(189, 100%, 15%)" },
  ".G": { colour: "hsl(108, 100%, 10%)" },
};
