const MAX_INT = 4294967296.0;
const N = 624;
const M = 397;
const UPPER_MASK = 0x80000000;
const LOWER_MASK = 0x7fffffff;
const MATRIX_A = 0x9908b0df;

/**
 * Instantiates a new Mersenne Twister.
 *
 * @param seed - The initial seed value.
 */
export class MersenneTwister {
  private mt: number[];
  private mti: number;

  constructor(seed?: number) {
    this.mt = new Array(N);
    this.mti = N + 1;
    this.seed(seed);
  }

  /**
   * Initializes the state vector by using one unsigned 32-bit integer "seed", which may be zero.
   *
   * @param seed - The seed value.
   */
  public seed(seed?: number): void {
    const sSeed = typeof seed === "undefined" ? new Date().getTime() : seed;
    this.mt[0] = sSeed >>> 0;

    for (this.mti = 1; this.mti < N; this.mti++) {
      const s = this.mt[this.mti - 1] ^ (this.mt[this.mti - 1] >>> 30);
      this.mt[this.mti] =
        ((((s & 0xffff0000) >>> 16) * 1812433253) << 16) +
        (s & 0x0000ffff) * 1812433253 +
        this.mti;
      this.mt[this.mti] >>>= 0;
    }
  }

  /**
   * Initializes the state vector by using an array of unsigned 32-bit integers.
   *
   * @param vector - The seed vector.
   */

  public seedArray(vector: number[]): void {
    let i = 1;
    let j = 0;
    const k = N > vector.length ? N : vector.length;
    let s: number;

    this.seed(19650218);

    for (let cnt = 0; cnt < k; cnt++) {
      s = this.mt[i - 1] ^ (this.mt[i - 1] >>> 30);
      this.mt[i] =
        (this.mt[i] ^
          (((((s & 0xffff0000) >>> 16) * 1664525) << 16) +
            (s & 0x0000ffff) * 1664525)) +
        vector[j] +
        j;
      this.mt[i] >>>= 0;
      i++;
      j++;
      if (i >= N) {
        this.mt[0] = this.mt[N - 1];
        i = 1;
      }
      if (j >= vector.length) {
        j = 0;
      }
    }

    for (let cnt = N - 1; cnt > 0; cnt--) {
      s = this.mt[i - 1] ^ (this.mt[i - 1] >>> 30);
      this.mt[i] =
        (this.mt[i] ^
          (((((s & 0xffff0000) >>> 16) * 1566083941) << 16) +
            (s & 0x0000ffff) * 1566083941)) -
        i;
      this.mt[i] >>>= 0;
      i++;
      if (i >= N) {
        this.mt[0] = this.mt[N - 1];
        i = 1;
      }
    }

    this.mt[0] = 0x80000000;
  }

  /**
   * Generates a random unsigned 32-bit integer.
   *
   * @returns A random unsigned 32-bit integer.
   */
  public int(): number {
    let y: number;
    let kk: number;
    const mag01 = [0, MATRIX_A];

    if (this.mti >= N) {
      if (this.mti === N + 1) {
        this.seed(5489);
      }

      for (kk = 0; kk < N - M; kk++) {
        y = (this.mt[kk] & UPPER_MASK) | (this.mt[kk + 1] & LOWER_MASK);
        this.mt[kk] = this.mt[kk + M] ^ (y >>> 1) ^ mag01[y & 1];
      }

      for (; kk < N - 1; kk++) {
        y = (this.mt[kk] & UPPER_MASK) | (this.mt[kk + 1] & LOWER_MASK);
        this.mt[kk] = this.mt[kk + (M - N)] ^ (y >>> 1) ^ mag01[y & 1];
      }

      y = (this.mt[N - 1] & UPPER_MASK) | (this.mt[0] & LOWER_MASK);
      this.mt[N - 1] = this.mt[M - 1] ^ (y >>> 1) ^ mag01[y & 1];
      this.mti = 0;
    }

    y = this.mt[this.mti++];
    y ^= y >>> 11;
    y ^= (y << 7) & 0x9d2c5680;
    y ^= (y << 15) & 0xefc60000;
    y ^= y >>> 18;

    return y >>> 0;
  }

  /**
   * Generates a random unsigned 31-bit integer.
   *
   * @returns A random unsigned 31-bit integer.
   */
  public int31(): number {
    return this.int() >>> 1;
  }

  /**
   * Generates a random real in the interval [0;1] with 32-bit resolution.
   *
   * @returns A random real in the interval [0;1].
   */
  public real(): number {
    return this.int() * (1.0 / (MAX_INT - 1));
  }

  /**
   * Generates a random real in the interval ]0;1[ with 32-bit resolution.
   *
   * @returns A random real in the interval ]0;1[.
   */
  public realx(): number {
    return (this.int() + 0.5) * (1.0 / MAX_INT);
  }

  /**
   * Generates a random real in the interval [0;1[ with 32-bit resolution.
   *
   * @returns A random real in the interval [0;1[.
   */
  public rnd(): number {
    return this.int() * (1.0 / MAX_INT);
  }

  /**
   * Generates a random real in the interval [0;1[ with 32-bit resolution.
   * Same as .rnd() method - for consistency with Math.random() interface.
   *
   * @returns A random real in the interval [0;1[.
   */
  public random(): number {
    return this.rnd();
  }

  /**
   * Generates a random real in the interval [0;1[ with 53-bit resolution.
   *
   * @returns A random real in the interval [0;1[.
   */
  public rndHiRes(): number {
    const a = this.int() >>> 5;
    const b = this.int() >>> 6;
    return (a * 67108864.0 + b) * (1.0 / 9007199254740992.0);
  }

  /**
   * A static version of rnd() on a randomly seeded instance.
   *
   * @returns A random real in the interval [0;1[.
   */
  public static random(): number {
    const instance = new MersenneTwister();
    return instance.rnd();
  }
}

function testMersenneTwister() {
  // Test 1: Default seed
  const mt1 = new MersenneTwister();
  console.log("Test 1: Default seed");
  console.log("int():", mt1.int() >= 0 && mt1.int() <= 4294967295);

  // Test 2: Custom seed
  const mt2 = new MersenneTwister(12345);
  console.log("\nTest 2: Custom seed");
  console.log("int():", mt2.int() >= 0 && mt2.int() <= 4294967295);

  // Test 3: seedArray
  const mt3 = new MersenneTwister();
  mt3.seedArray([1, 2, 3, 4, 5]);
  console.log("\nTest 3: seedArray");
  console.log("int():", mt3.int() >= 0 && mt3.int() <= 4294967295);

  // Test 4: int31
  console.log("\nTest 4: int31");
  console.log("int31():", mt2.int31() >= 0 && mt2.int31() <= 2147483647);

  // Test 5: real
  console.log("\nTest 5: real");
  console.log("real():", mt2.real() >= 0 && mt2.real() <= 1);

  // Test 6: realx
  console.log("\nTest 6: realx");
  console.log("realx():", mt2.realx() > 0 && mt2.realx() < 1);

  // Test 7: rnd
  console.log("\nTest 7: rnd");
  console.log("rnd():", mt2.rnd() >= 0 && mt2.rnd() < 1);

  // Test 8: random
  console.log("\nTest 8: random");
  console.log("random():", mt2.random() >= 0 && mt2.random() < 1);

  // Test 9: rndHiRes
  console.log("\nTest 9: rndHiRes");
  console.log("rndHiRes():", mt2.rndHiRes() >= 0 && mt2.rndHiRes() < 1);

  // Test 10: static random
  console.log("\nTest 10: static random");
  console.log(
    "MersenneTwister.random():",
    MersenneTwister.random() >= 0 && MersenneTwister.random() < 1,
  );

  // Test 11: Reproducibility with same seed
  const mt4 = new MersenneTwister(12345);
  const mt5 = new MersenneTwister(12345);
  const seq1 = [mt4.int(), mt4.int(), mt4.int()];
  const seq2 = [mt5.int(), mt5.int(), mt5.int()];
  console.log("\nTest 11: Reproducibility with same seed");
  console.log(
    "Same sequence:",
    seq1[0] === seq2[0] && seq1[1] === seq2[1] && seq1[2] === seq2[2],
  );

  // Test 12: Reproducibility with seedArray
  const mt6 = new MersenneTwister();
  const mt7 = new MersenneTwister();
  mt6.seedArray([1, 2, 3, 4, 5]);
  mt7.seedArray([1, 2, 3, 4, 5]);
  const seq3 = [mt6.int(), mt6.int(), mt6.int()];
  const seq4 = [mt7.int(), mt7.int(), mt7.int()];
  console.log("\nTest 12: Reproducibility with seedArray");
  console.log(
    "Same sequence:",
    seq3[0] === seq4[0] && seq3[1] === seq4[1] && seq3[2] === seq4[2],
  );
}
