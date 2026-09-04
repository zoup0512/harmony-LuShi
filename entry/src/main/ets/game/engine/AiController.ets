/**
 * 酒馆战棋 - AI 控制器
 *
 * AI 在每个准备回合自主决策：买什么、卖什么、何时升级、如何排兵。
 * 策略遵循战棋基本常识：
 * 1. 优先购买高身材/带关键词（嘲讽、圣盾、亡语）的随从；
 * 2. 倾向同种族成体系（鱼人/机械/龙等）；
 * 3. 场上未满时尽量铺场；
 * 4. 金币充裕时升级酒馆；
 * 5. 把嘲讽放在两侧保护核心，攻击高的放中间。
 *
 * 这是一个"启发式"AI，足够提供挑战又不会过于复杂。
 */

import { PlayerState } from '../model/Hero';
import { Minion, MinionDef } from '../model/Minion';
import { Keyword } from '../model/Types';
import { ALL_MINIONS, MINION_BY_ID, goldenVersion } from '../data/MinionLibrary';
import { GameConfig } from '../GameConfig';
import { Rng, nextUid } from '../util/Rng';

export class AiController {
  private ai: PlayerState;
  private opponent: PlayerState;
  private rng: Rng;

  constructor(ai: PlayerState, opponent: PlayerState, rng: Rng) {
    this.ai = ai;
    this.opponent = opponent;
    this.rng = rng;
  }

  /** 执行一整个 AI 回合 */
  executeTurn(): void {
    // 优先升级（如果有闲钱且场上已成型）
    this.maybeUpgrade();

    // 反复购买直到没钱或没空位
    let guard = 0;
    while (guard++ < 30) {
      if (!this.buyBest()) break;
    }

    // 排兵布阵
    this.arrangeBoard();

    // 剩余金币刷新一两次寻找更好的卡
    guard = 0;
    while (this.ai.gold >= 2 && guard++ < 2) {
      this.refreshShopInternal();
      if (!this.buyBest()) break;
    }
    this.arrangeBoard();
  }

  /** 评估是否升级酒馆 */
  private maybeUpgrade(): void {
    // 当回合数 >= 3 且金币足够时升级
    if (this.ai.tavernTier < 6 && this.ai.gold >= this.ai.upgradeCost + 2) {
      this.ai.gold -= this.ai.upgradeCost;
      this.ai.tavernTier++;
      this.ai.upgradeCost = GameConfig.upgradeCost(this.ai.tavernTier);
    }
  }

  /** 购买评分最高的随从 */
  private buyBest(): boolean {
    if (this.ai.hand.length >= 10) return false;
    let bestIdx = -1;
    let bestScore = -1;
    for (let i = 0; i < this.ai.shop.length; i++) {
      const m = this.ai.shop[i];
      const def = MINION_BY_ID.get(m.defId);
      if (!def) continue;
      const cost = GameConfig.buyCost(def.tier);
      if (this.ai.gold < cost) continue;
      const score = this.scoreMinion(def);
      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }
    if (bestIdx < 0) return false;

    const m = this.ai.shop[bestIdx];
    const def = MINION_BY_ID.get(m.defId)!;
    const cost = GameConfig.buyCost(def.tier);
    this.ai.gold -= cost;
    this.ai.shop.splice(bestIdx, 1);
    this.ai.hand.push(m);
    this.checkTriple(this.ai, m.defId);
    return true;
  }

  /**
   * 给一张随从打分：综合身材、关键词、与现有阵型的种族协同。
   */
  private scoreMinion(def: MinionDef): number {
    let score = def.atk + def.hp; // 身材基础分
    // 关键词加分
    if (def.keywords.indexOf(Keyword.TAUNT) >= 0) score += 3;
    if (def.keywords.indexOf(Keyword.DIVINE_SHIELD) >= 0) score += 5;
    if (def.keywords.indexOf(Keyword.POISONOUS) >= 0) score += 4;
    if (def.keywords.indexOf(Keyword.WINDFURY) >= 0) score += 4;
    if (def.keywords.indexOf(Keyword.REBORN) >= 0) score += 2;
    if (def.triggers.length > 0) score += 3; // 有触发能力
    // 同族协同：场上已有该种族则加分
    const sameTribeOnBoard = this.ai.board.filter((b) => {
      const d = MINION_BY_ID.get(b.defId);
      return d && d.tribe === def.tribe;
    }).length;
    score += sameTribeOnBoard * 2;
    return score;
  }

  /** 把手中随从尽量上到战场 */
  private arrangeBoard(): void {
    // 先把手中随从上场
    while (this.ai.hand.length > 0 && this.ai.board.length < GameConfig.BOARD_SIZE) {
      const m = this.ai.hand.shift()!;
      this.ai.board.push(m);
    }
    // 如果超过 7，卖掉评分最低的
    while (this.ai.board.length > GameConfig.BOARD_SIZE) {
      let worstIdx = 0;
      let worstScore = Number.MAX_VALUE;
      for (let i = 0; i < this.ai.board.length; i++) {
        const def = MINION_BY_ID.get(this.ai.board[i].defId);
        const s = def ? this.scoreMinion(def) : 0;
        if (s < worstScore) {
          worstScore = s;
          worstIdx = i;
        }
      }
      this.ai.board.splice(worstIdx, 1);
    }
    // 排序：嘲讽靠两侧，高攻在中
    this.ai.board.sort((a, b) => {
      const aTaunt = a.hasKeyword(Keyword.TAUNT) ? 1 : 0;
      const bTaunt = b.hasKeyword(Keyword.TAUNT) ? 1 : 0;
      if (aTaunt !== bTaunt) return aTaunt - bTaunt;
      return b.atk - a.atk;
    });
  }

  private refreshShopInternal(): void {
    if (this.ai.gold < GameConfig.REFRESH_COST) return;
    this.ai.gold -= GameConfig.REFRESH_COST;
    const size = GameConfig.shopSize(this.ai.tavernTier);
    this.ai.shop = [];
    const pool = this.shopPool(this.ai.tavernTier);
    for (let i = 0; i < size; i++) {
      if (pool.length === 0) break;
      const idx = this.rng.nextInt(pool.length);
      this.ai.shop.push(new Minion(pool[idx], nextUid()));
    }
  }

  private shopPool(tavernTier: number): MinionDef[] {
    return ALL_MINIONS.filter((m) => m.tier <= tavernTier && m.tier >= 1);
  }

  /** 三连检测（与引擎一致，复用同逻辑） */
  private checkTriple(p: PlayerState, defId: number): void {
    const same = p.hand.filter((m) => m.defId === defId && !m.golden);
    if (same.length >= GameConfig.TRIPLE_COUNT) {
      let removed = 0;
      p.hand = p.hand.filter((m) => {
        if (m.defId === defId && !m.golden && removed < GameConfig.TRIPLE_COUNT) {
          removed++;
          return false;
        }
        return true;
      });
      const baseDef = MINION_BY_ID.get(defId)!;
      p.hand.push(new Minion(goldenVersion(baseDef), nextUid()));
    }
  }
}
