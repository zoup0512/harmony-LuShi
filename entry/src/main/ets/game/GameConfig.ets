/**
 * 酒馆战棋 - 全局游戏配置常量
 *
 * 把规则相关的可调参数集中在此，方便平衡性调整。
 * 数值参考炉石酒馆战棋的标准规则，并为单机对 AI 的节奏做轻微优化。
 */

export class GameConfig {
  /** 初始金币（每个准备回合开始时重置到该值，随回合增加） */
  static readonly BASE_GOLD: number = 3;
  /** 金币上限 */
  static readonly MAX_GOLD: number = 10;
  /** 战场随从上限 */
  static readonly BOARD_SIZE: number = 7;
  /** 商店可购买随从数量上限（随酒馆等级增长） */
  static readonly SHOP_SIZES: number[] = [3, 4, 4, 5, 5, 6];
  /** 升级到下一级酒馆所需金币（按当前等级查表） */
  static readonly UPGRADE_COST: number[] = [5, 5, 6, 6, 7, 0];
  /** 刷新商店花费 */
  static readonly REFRESH_COST: number = 1;
  /** 随从购买价（按星级） */
  static readonly BUY_COST: number[] = [0, 3, 3, 4, 5, 5, 6];
  /** 卖出随从返还金币 */
  static readonly SELL_VALUE: number = 1;
  /** 三连所需同名随从数量 */
  static readonly TRIPLE_COUNT: number = 3;
  /** 游戏结束血量阈值（≤0 即败） */
  static readonly DEATH_HP: number = 0;

  /** 根据酒馆等级计算本次商店可拥有的随从数量 */
  static shopSize(tavernTier: number): number {
    const idx = Math.min(Math.max(tavernTier, 1), 6) - 1;
    return GameConfig.SHOP_SIZES[idx];
  }

  /** 升级费用 */
  static upgradeCost(tavernTier: number): number {
    const idx = Math.min(Math.max(tavernTier, 1), 6) - 1;
    return GameConfig.UPGRADE_COST[idx];
  }

  /** 购买某星级随从的费用 */
  static buyCost(tier: number): number {
    const idx = Math.min(Math.max(tier, 1), 6);
    return GameConfig.BUY_COST[idx];
  }

  /** 回合数对应的本回合金币（第 n 回合 = min(BASE+n-1, MAX)） */
  static goldForRound(round: number): number {
    return Math.min(GameConfig.BASE_GOLD + round - 1, GameConfig.MAX_GOLD);
  }
}
