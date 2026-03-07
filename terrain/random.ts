export class MersenneTwister {
  private N = 624;
  private M = 397;
  private MATRIX_A = 0x9908b0df;
  private UPPER_MASK = 0x80000000;
  private LOWER_MASK = 0x7fffffff;
  private mt: number[] = new Array(this.N);
  private mti: number = this.N + 1;

  constructor(seed: number = 5489) {
    this.init_genrand(seed);
  }

  private init_genrand(s: number): void {
    this.mt[0] = s >>> 0;
    for (this.mti = 1; this.mti < this.N; this.mti++) {
      s = this.mt[this.mti - 1] ^ (this.mt[this.mti - 1] >>> 30);
      this.mt[this.mti] =
        ((((s & 0xffff0000) >>> 16) * 1812433253) << 16) +
        (s & 0x0000ffff) * 1812433253 +
        this.mti;
      this.mt[this.mti] >>>= 0;
    }
  }

  private twist(): void {
    let i = 0;
    let x: number;
    let xA: number;

    for (; i < this.N - this.M; i++) {
      x = (this.mt[i] & this.UPPER_MASK) | (this.mt[i + 1] & this.LOWER_MASK);
      xA = x >>> 1;
      if (x % 2 !== 0) {
        xA = xA ^ this.MATRIX_A;
      }
      this.mt[i] = this.mt[i + this.M] ^ xA;
    }
    for (; i < this.N - 1; i++) {
      x = (this.mt[i] & this.UPPER_MASK) | (this.mt[i + 1] & this.LOWER_MASK);
      xA = x >>> 1;
      if (x % 2 !== 0) {
        xA = xA ^ this.MATRIX_A;
      }
      this.mt[i] = this.mt[i + (this.M - this.N)] ^ xA;
    }
    x =
      (this.mt[this.N - 1] & this.UPPER_MASK) | (this.mt[0] & this.LOWER_MASK);
    xA = x >>> 1;
    if (x % 2 !== 0) {
      xA = xA ^ this.MATRIX_A;
    }
    this.mt[this.N - 1] = this.mt[this.M - 1] ^ xA;

    this.mti = 0;
  }

  public genrand_int32(): number {
    let y: number;
    if (this.mti >= this.N) {
      this.twist();
    }

    y = this.mt[this.mti++];
    y ^= y >>> 11;
    y ^= (y << 7) & 0x9d2c5680;
    y ^= (y << 15) & 0xefc60000;
    y ^= y >>> 18;

    return y >>> 0;
  }

  public random(): number {
    return this.genrand_int32() * (1.0 / 4294967296.0);
  }
}
