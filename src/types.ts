export type TileID =
  | "?" // null
  | " " // empty
  | "|" // wall
  | "-" // floor
  | "!" // lava
  | "#" // soil
  | "£" // goal
  | "@" // boulder
  | "b" // bronze
  | "s" // silver
  | "S"
  | "g" // gold
  | "w" // water/sapphire
  | "e" // gas/emerald
  | "d" // diamond
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
export type Subgrid = Array<SubtileID | undefined>[];
