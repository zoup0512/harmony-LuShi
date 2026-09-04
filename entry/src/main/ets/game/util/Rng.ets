/**
 * 酒馆战棋 - 随机数与工具函数
 *
 * 把随机操作集中到一个模块，便于：
 * 1) 在 AI 对战模拟时注入可重复的伪随机种子；
 * 2) 统一"取数组随机元素"、"洗牌"等常用操作。
 */

/** 简单的可种子化伪随机（线性同余），保证 AI 模拟可复现。 */
export class Rng {
  private state: number;

  constructor(seed: number = Date.now()) {
    this.state = seed >>> 0;
  }

  /** 返回 [0, 1) 区间的浮点随机数 */
  next(): number {
    // LCG 常数取自 glibc
    this.state = (Math.imul(this.state, 1103515245) + 12345) >>> 0;
    return this.state / 0x100000000;
  }

  /** 返回 [0, max) 区间的整数 */
  nextInt(max: number): number {
    return Math.floor(this.next() * max);
  }

  /** 返回 [min, max] 区间的整数（含两端） */
  rangeInt(min: number, max: number): number {
    return min + this.nextInt(max - min + 1);
  }

  /** 以概率 p 返回 true（p∈[0,1]） */
  chance(p: number): boolean {
    return this.next() < p;
  }

  /** 从数组中随机取一个元素 */
  pick<T>(arr: T[]): T {
    return arr[this.nextInt(arr.length)];
  }

  /** Fisher–Yates 原地洗牌 */
  shuffle<T>(arr: T[]): T[] {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = this.nextInt(i + 1);
      const tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }
}

/** 默认全局随机数（用真实时间作种子） */
export const RNG: Rng = new Rng();

/** 全局自增的随从实例 id 生成器 */
let UID_COUNTER = 1;
export function nextUid(): number {
  return UID_COUNTER++;
}
