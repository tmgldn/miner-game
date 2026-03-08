export type GameState = {
  fluids: Pixel[];
};

export type TileID =
  | "|"
  | "-"
  | "?"
  | "!"
  | " "
  | "#"
  | "£"
  | "@"
  | "b"
  | "s"
  | "S"
  | "g"
  | "w"
  | "e"
  | "d"
  | "G"
  | "W"
  | "E"
  | "D";
export type Position = { x: number; y: number };

export interface TileMetadata {
  colour: string;
}

export type Grid = TileID[][];
export type GridOptions = {
  W: number;
  H: number;
  CHUTE_DEPTH: number;
  SEED: number;
};

export type SubtileID = ".W" | ".G";
export type Subgrid = Map<number, SubtileID>[];
