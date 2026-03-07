declare module "term-kitty-img" {
  function terminalKittyImage(
    imgStr: string | Buffer,
    opts?: {
      fallback?: () => void;
    },
  ): void;
}
declare module "fastnoise-lite" {
  namespace FastNoiseLite {
    // Enums
    const NoiseType: {
      OpenSimplex2: "OpenSimplex2";
      OpenSimplex2S: "OpenSimplex2S";
      Cellular: "Cellular";
      Perlin: "Perlin";
      ValueCubic: "ValueCubic";
      Value: "Value";
    };

    const RotationType3D: {
      None: "None";
      ImproveXYPlanes: "ImproveXYPlanes";
      ImproveXZPlanes: "ImproveXZPlanes";
    };

    const FractalType: {
      None: "None";
      FBm: "FBm";
      Ridged: "Ridged";
      PingPong: "PingPong";
    };

    const DomainWarpFractalType: {
      None: "None";
      DomainWarpProgressive: "DomainWarpProgressive";
      DomainWarpIndependent: "DomainWarpIndependent";
    };

    const CellularDistanceFunction: {
      Euclidean: "Euclidean";
      EuclideanSq: "EuclideanSq";
      Manhattan: "Manhattan";
      Hybrid: "Hybrid";
    };

    const CellularReturnType: {
      CellValue: "CellValue";
      Distance: "Distance";
      Distance2: "Distance2";
      Distance2Add: "Distance2Add";
      Distance2Sub: "Distance2Sub";
      Distance2Mul: "Distance2Mul";
      Distance2Div: "Distance2Div";
    };

    const DomainWarpType: {
      OpenSimplex2: "OpenSimplex2";
      OpenSimplex2Reduced: "OpenSimplex2Reduced";
      BasicGrid: "BasicGrid";
    };

    const TransformType3D: {
      None: "None";
      ImproveXYPlanes: "ImproveXYPlanes";
      ImproveXZPlanes: "ImproveXZPlanes";
      DefaultOpenSimplex2: "DefaultOpenSimplex2";
    };

    // Types
    type Vector2 = { x: number; y: number };
    type Vector3 = { x: number; y: number; z: number };

    type NoiseType = (typeof NoiseType)[keyof typeof NoiseType];
    type RotationType3D = (typeof RotationType3D)[keyof typeof RotationType3D];
    type FractalType = (typeof FractalType)[keyof typeof FractalType];
    type DomainWarpFractalType =
      (typeof DomainWarpFractalType)[keyof typeof DomainWarpFractalType];
    type CellularDistanceFunction =
      (typeof CellularDistanceFunction)[keyof typeof CellularDistanceFunction];
    type CellularReturnType =
      (typeof CellularReturnType)[keyof typeof CellularReturnType];
    type DomainWarpType = (typeof DomainWarpType)[keyof typeof DomainWarpType];
    type TransformType3D =
      (typeof TransformType3D)[keyof typeof TransformType3D];

    // Interface
    interface NoiseInstance {
      SetSeed(seed: number): void;
      SetFrequency(frequency: number): void;
      SetNoiseType(noiseType: NoiseType): void;
      SetRotationType3D(rotationType: RotationType3D): void;
      SetFractalType(fractalType: FractalType): void;
      SetFractalOctaves(octaves: number): void;
      SetFractalLacunarity(lacunarity: number): void;
      SetFractalGain(gain: number): void;
      SetFractalWeightedStrength(weightedStrength: number): void;
      SetFractalPingPongStrength(pingPongStrength: number): void;
      SetCellularDistanceFunction(cdf: CellularDistanceFunction): void;
      SetCellularReturnType(crt: CellularReturnType): void;
      SetCellularJitter(modifier: number): void;
      SetDomainWarpType(dwt: DomainWarpType): void;
      SetDomainWarpAmp(amplitude: number): void;
      SetDomainWarpSeed(seed: number): void;
      SetDomainWarpFrequency(frequency: number): void;
      SetDomainWarpFractalType(fractalType: DomainWarpFractalType): void;
      SetDomainWarpFractalOctaves(octaves: number): void;
      SetDomainWarpFractalLacunarity(lacunarity: number): void;
      SetDomainWarpFractalGain(gain: number): void;
      GetNoise(x: number, y: number, z?: number): number;
      DomainWrap(coord: Vector2 | Vector3): void;
    }
  }

  // Constructor
  class FastNoiseLite implements FastNoiseLite.NoiseInstance {
    constructor(seed?: number);
    SetSeed(seed: number): void;
    SetFrequency(frequency: number): void;
    SetNoiseType(noiseType: FastNoiseLite.NoiseType): void;
    SetRotationType3D(rotationType: FastNoiseLite.RotationType3D): void;
    SetFractalType(fractalType: FastNoiseLite.FractalType): void;
    SetFractalOctaves(octaves: number): void;
    SetFractalLacunarity(lacunarity: number): void;
    SetFractalGain(gain: number): void;
    SetFractalWeightedStrength(weightedStrength: number): void;
    SetFractalPingPongStrength(pingPongStrength: number): void;
    SetCellularDistanceFunction(
      cdf: FastNoiseLite.CellularDistanceFunction,
    ): void;
    SetCellularReturnType(crt: FastNoiseLite.CellularReturnType): void;
    SetCellularJitter(modifier: number): void;
    SetDomainWarpType(dwt: FastNoiseLite.DomainWarpType): void;
    SetDomainWarpAmp(amplitude: number): void;
    SetDomainWarpSeed(seed: number): void;
    SetDomainWarpFrequency(frequency: number): void;
    SetDomainWarpFractalType(
      fractalType: FastNoiseLite.DomainWarpFractalType,
    ): void;
    SetDomainWarpFractalOctaves(octaves: number): void;
    SetDomainWarpFractalLacunarity(lacunarity: number): void;
    SetDomainWarpFractalGain(gain: number): void;
    GetNoise(x: number, y: number, z?: number): number;
    DomainWrap(coord: FastNoiseLite.Vector2 | FastNoiseLite.Vector3): void;
  }

  export = FastNoiseLite;
  export default FastNoiseLite;
}
