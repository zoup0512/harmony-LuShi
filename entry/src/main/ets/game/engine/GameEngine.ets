/**
 * 酒馆战棋 - 主游戏引擎
 *
 * 管理整局游戏的宏观流程：回合开始 → 准备阶段（买/卖/升级/排兵） → 战斗 → 结算 → 下一回合。
 *
 * 引擎持有玩家与 AI 的 PlayerState，所有操作（买、卖、刷新、升级、冻结、上随从）
 * 都通过本类的方法进行，确保规则一致性与状态可观测。引擎本身不持有 UI 状态，
 * UI 层通过订阅 onStateChange 回调来感知变化。
 */

import { PlayerState, HeroDef, HeroSkillTarget } from '../model/Hero';
import { Minion, MinionDef } from '../model/Minion';
import { Keyword, Phase, Side } from '../model/Types';
import { EffectData, EffectType, TargetMode, Trigger } from '../model/Trigger';
import {
  ALL_MINIONS, MINION_BY_ID, goldenVersion, effectiveDefinition
} from '../data/MinionLibrary';
import { randomHero } from '../data/HeroLibrary';
import { GameConfig } from '../GameConfig';
import { Rng, RNG, nextUid } from '../util/Rng';
import { simulateBattle } from '../combat/BattleSimulator';
import { BattleOutcome, BattleResult } from '../combat/CombatTypes';
import { AiController } from './AiController';

/** 引擎对外广播的状态变更回调 */
export type StateListener = () => void;

/** 战斗结算后的回调，参数为战斗结果与对玩家造成的伤害 */
export type BattleResolvedListener = (result: BattleResult, playerDamage: number) => void;

/** 游戏结束回调 */
export type GameOverListener = (playerWon: boolean) => void;

export class GameEngine {
  /** 玩家状态 */
  player: PlayerState;
  /** AI 状态 */
  ai: PlayerState;
  /** 当前回合数（从 1 开始） */
  round: number = 1;
  /** 当前阶段 */
  phase: Phase = Phase.MENU;
  /** AI 控制器 */
  aiController: AiController;
  /** 随机源 */
  rng: Rng;
  /** 冻结标记：玩家是否冻结当前商店（下回合不刷新） */
  frozen: boolean = false;

  private stateListeners: StateListener[] = [];
  private battleListeners: BattleResolvedListener[] = [];
  private gameOverListeners: GameOverListener[] = [];

  constructor(playerHero: HeroDef, rng: Rng = RNG) {
    this.rng = rng;
    this.player = new PlayerState(playerHero);
    this.ai = new PlayerState(randomHero());
    this.aiController = new AiController(this.ai, this.player, rng);
    this.phase = Phase.RECRUIT;
    this.startRecruitPhase(true);
  }

  // ---------------- 订阅 ----------------

  onStateChange(fn: StateListener): void {
    this.stateListeners.push(fn);
  }

  onBattleResolved(fn: BattleResolvedListener): void {
    this.battleListeners.push(fn);
  }

  onGameOver(fn: GameOverListener): void {
    this.gameOverListeners.push(fn);
  }

  /** 通知所有监听者状态已更新 */
  notify(): void {
    for (const fn of this.stateListeners) fn();
  }

  // ---------------- 准备阶段 ----------------

  /**
   * 开始准备阶段：发放金币、刷新商店（除非冻结）、重置技能、触发回合开始效果。
   */
  startRecruitPhase(firstRound: boolean = false): void {
    this.phase = Phase.RECRUIT;
    // 发放金币
    this.player.gold = GameConfig.goldForRound(this.round);
    this.ai.gold = GameConfig.goldForRound(this.round);
    // 升级费用（每回合 -1，最低为本级实际费用）
    this.player.upgradeCost = GameConfig.upgradeCost(this.player.tavernTier);
    this.ai.upgradeCost = GameConfig.upgradeCost(this.ai.tavernTier);

    // 刷新商店（首回合或未冻结）
    if (firstRound || !this.frozen) {
      this.refillShop(this.player);
    }
    this.refillShop(this.ai);
    this.frozen = false;

    // 触发回合开始效果（仅作用于准备阶段的"成长"类随从，如招潮者）
    this.triggerTurnStartForBoard(this.player.board, Side.PLAYER);

    this.player.skillUsed = false;
    this.ai.skillUsed = false;

    this.notify();
  }

  /**
   * 触发某方战场上随从的"回合开始"效果。
   * 注意：这些是准备阶段成长类效果（如招潮者 +1/+1），不是战斗内触发。
   */
  private triggerTurnStartForBoard(board: Minion[], side: Side): void {
    for (const m of board) {
      const def = effectiveDefinition(m);
      if (!def) continue;
      for (const trig of def.triggers) {
        if (trig.trigger !== Trigger.ON_TURN_START) continue;
        for (const eff of trig.effects) {
          this.applyRecruitEffect(eff, m, board, side);
        }
      }
    }
  }

  /**
   * 在准备阶段应用效果（简化版：仅处理 buff 与召唤，不含伤害）。
   */
  private applyRecruitEffect(eff: EffectData, owner: Minion, board: Minion[], side: Side): void {
    if (eff.type === EffectType.SUMMON) {
      const def = MINION_BY_ID.get(eff.summonId);
      if (!def) return;
      for (let i = 0; i < eff.value && board.length < GameConfig.BOARD_SIZE; i++) {
        board.push(new Minion(def, nextUid()));
      }
      return;
    }

    const targets = this.selectRecruitTargets(eff.target, owner, board);
    for (const t of targets) {
      if (eff.type === EffectType.BUFF_STATS) {
        t.atk += eff.atkDelta;
        t.hp += eff.hpDelta;
        t.maxHp = Math.max(t.maxHp, t.hp);
      } else if (eff.type === EffectType.GIVE_DIVINE_SHIELD) {
        t.addKeyword(Keyword.DIVINE_SHIELD);
      } else if (eff.type === EffectType.GIVE_TAUNT) {
        t.addKeyword(Keyword.TAUNT);
      } else if (eff.type === EffectType.GIVE_WINDFURY) {
        t.addKeyword(Keyword.WINDFURY);
      }
    }
  }

  private selectRecruitTargets(mode: TargetMode, owner: Minion, board: Minion[]): Minion[] {
    const def = effectiveDefinition(owner);
    switch (mode) {
      case TargetMode.SELF: return [owner];
      case TargetMode.RANDOM_FRIENDLY:
        return board.length > 0 ? [this.rng.pick(board)] : [];
      case TargetMode.ALL_FRIENDLY: return board.slice();
      case TargetMode.SAME_TRIBE: {
        if (!def) return [];
        return board.filter((m) => {
          const d = effectiveDefinition(m);
          return d && d.tribe === def.tribe;
        });
      }
      default: return [];
    }
  }

  // ---------------- 商店操作 ----------------

  /** 重新填满某玩家的商店（从卡池中按酒馆等级抽取） */
  refillShop(p: PlayerState): void {
    const size = GameConfig.shopSize(p.tavernTier);
    p.shop = [];
    const pool = this.shopPool(p.tavernTier);
    for (let i = 0; i < size; i++) {
      if (pool.length === 0) break;
      const idx = this.rng.nextInt(pool.length);
      const def = pool[idx];
      p.shop.push(new Minion(def, nextUid()));
    }
  }

  /** 获取某酒馆等级可用的卡池（该级及以下） */
  shopPool(tavernTier: number): MinionDef[] {
    return ALL_MINIONS.filter((m) => m.tier <= tavernTier && m.tier >= 1);
  }

  /** 刷新商店（花费 1 金币） */
  refreshShop(): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    if (this.player.gold < GameConfig.REFRESH_COST) return false;
    this.player.gold -= GameConfig.REFRESH_COST;
    this.refillShop(this.player);
    this.notify();
    return true;
  }

  /** 冻结/解冻当前商店 */
  toggleFreeze(): void {
    this.frozen = !this.frozen;
    this.notify();
  }

  /** 购买商店中的随从到手中 */
  buyMinion(shopIndex: number): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    if (shopIndex < 0 || shopIndex >= this.player.shop.length) return false;
    if (this.player.hand.length >= 10) return false;
    const m = this.player.shop[shopIndex];
    const cost = GameConfig.buyCost(effectiveDefinition(m)!.tier);
    if (this.player.gold < cost) return false;
    this.player.gold -= cost;
    this.player.shop.splice(shopIndex, 1);
    // 战吼效果
    this.triggerBattlecry(m, this.player);
    this.player.hand.push(m);
    this.checkTripleInHand(this.player, m.defId);
    this.notify();
    return true;
  }

  /** 触发随从的战吼效果 */
  private triggerBattlecry(m: Minion, p: PlayerState): void {
    const def = effectiveDefinition(m);
    if (!def) return;
    for (const trig of def.triggers) {
      if (trig.trigger !== Trigger.BATTLECRY) continue;
      for (const eff of trig.effects) {
        this.applyRecruitEffect(eff, m, p.board, p === this.player ? Side.PLAYER : Side.AI);
      }
    }
  }

  /**
   * 检查手中是否有三张同名随从，若满足则升级为金色。
   */
  private checkTripleInHand(p: PlayerState, defId: number): void {
    const same = p.hand.filter((m) => m.defId === defId && !m.golden);
    if (same.length >= GameConfig.TRIPLE_COUNT) {
      // 移除三张
      let removed = 0;
      p.hand = p.hand.filter((m) => {
        if (m.defId === defId && !m.golden && removed < GameConfig.TRIPLE_COUNT) {
          removed++;
          return false;
        }
        return true;
      });
      // 加入一张金色版本
      const baseDef = MINION_BY_ID.get(defId)!;
      const goldenDef = goldenVersion(baseDef);
      p.hand.push(new Minion(goldenDef, nextUid()));
    }
  }

  /** 从手牌打出随从到战场 */
  playFromHand(handIndex: number, boardIndex: number = -1): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    if (handIndex < 0 || handIndex >= this.player.hand.length) return false;
    if (this.player.board.length >= GameConfig.BOARD_SIZE) return false;
    const m = this.player.hand.splice(handIndex, 1)[0];
    if (boardIndex < 0 || boardIndex >= this.player.board.length) {
      this.player.board.push(m);
    } else {
      this.player.board.splice(boardIndex, 0, m);
    }
    this.notify();
    return true;
  }

  /** 卖出随从（返还 1 金币） */
  sellMinion(board: boolean, index: number): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    const arr = board ? this.player.board : this.player.hand;
    if (index < 0 || index >= arr.length) return false;
    arr.splice(index, 1);
    this.player.gold = Math.min(this.player.gold + GameConfig.SELL_VALUE, GameConfig.MAX_GOLD);
    this.notify();
    return true;
  }

  /** 升级酒馆等级 */
  upgradeTavern(): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    if (this.player.tavernTier >= 6) return false;
    if (this.player.gold < this.player.upgradeCost) return false;
    this.player.gold -= this.player.upgradeCost;
    this.player.tavernTier++;
    this.player.upgradeCost = GameConfig.upgradeCost(this.player.tavernTier);
    this.notify();
    return true;
  }

  /** 调整战场上随从的顺序（拖拽换位） */
  reorderBoard(from: number, to: number): void {
    if (from < 0 || from >= this.player.board.length) return;
    if (to < 0 || to >= this.player.board.length) return;
    const m = this.player.board.splice(from, 1)[0];
    this.player.board.splice(to, 0, m);
    this.notify();
  }

  /** 使用英雄技能 */
  useHeroSkill(): boolean {
    if (this.phase !== Phase.RECRUIT) return false;
    if (this.player.skillUsed) return false;
    const skill = this.player.hero.skill;
    if (!skill) return false;
    if (this.player.gold < skill.cost) return false;

    this.player.gold -= skill.cost;
    this.player.skillUsed = true;

    // 根据技能目标语义执行
    if (skill.target === HeroSkillTarget.REFRESH_SHOP) {
      this.refillShop(this.player);
    } else if (skill.target === HeroSkillTarget.SELF_RANDOM_MINION) {
      if (this.player.board.length > 0) {
        this.applyRecruitEffect(
          skill.effect, this.rng.pick(this.player.board),
          this.player.board, Side.PLAYER
        );
      }
    } else if (skill.target === HeroSkillTarget.SELF_ALL_MINION) {
      for (const m of this.player.board) {
        this.applyRecruitEffect(skill.effect, m, this.player.board, Side.PLAYER);
      }
    } else if (skill.target === HeroSkillTarget.GIVE_KEYWORD) {
      if (this.player.board.length > 0) {
        this.applyRecruitEffect(
          skill.effect, this.rng.pick(this.player.board),
          this.player.board, Side.PLAYER
        );
      }
    }
    this.notify();
    return true;
  }

  // ---------------- 战斗阶段 ----------------

  /**
   * 结束准备阶段，进入战斗。
   * AI 先执行它的准备阶段策略（购买/排兵），然后模拟战斗。
   */
  endRecruitAndFight(): void {
    if (this.phase !== Phase.RECRUIT) return;

    // AI 执行策略
    this.aiController.executeTurn();

    // 进入战斗阶段
    this.phase = Phase.COMBAT;
    this.notify();

    // 模拟战斗
    const result = simulateBattle(this.player.board, this.ai.board, this.rng);

    // 结算英雄伤害
    let playerDamage = 0;
    if (result.outcome === BattleOutcome.AI_WIN) {
      playerDamage = result.playerDamageTaken;
      this.player.health -= playerDamage;
    } else if (result.outcome === BattleOutcome.PLAYER_WIN) {
      this.ai.health -= result.aiDamageTaken;
    }

    // 通知 UI 战斗结束
    for (const fn of this.battleListeners) fn(result, playerDamage);

    // 检查游戏结束
    if (this.player.health <= GameConfig.DEATH_HP || this.ai.health <= GameConfig.DEATH_HP) {
      this.phase = Phase.GAME_OVER;
      const playerWon = this.ai.health <= GameConfig.DEATH_HP &&
        this.player.health > GameConfig.DEATH_HP;
      for (const fn of this.gameOverListeners) fn(playerWon);
      this.notify();
      return;
    }

    // 进入下一回合
    this.round++;
    // 清空战场（战斗后的随从消失，准备阶段从手牌重新上场）
    this.player.board = [];
    this.ai.board = [];
    this.startRecruitPhase(false);
  }

  /** 获取玩家剩余血量百分比（0-1，用于 UI 血条） */
  playerHealthRatio(): number {
    return Math.max(0, this.player.health) / this.player.hero.baseHealth;
  }

  aiHealthRatio(): number {
    return Math.max(0, this.ai.health) / this.ai.hero.baseHealth;
  }
}
