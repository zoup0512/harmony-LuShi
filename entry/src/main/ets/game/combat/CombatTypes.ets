/**
 * 酒馆战棋 - 战斗事件日志
 *
 * 自动战斗过程会产生一连串"事件"（攻击、圣盾抵消、亡语触发、随从死亡等）。
 * 这些事件按顺序记录到日志中，UI 层据此播放动画并更新显示，从而把"战斗逻辑"
 * 和"动画展示"完全解耦：引擎纯计算，UI 纯渲染。
 */

import { Side } from '../model/Types';
import { Minion } from '../model/Minion';

/** 战斗事件类型 */
export enum CombatEventType {
  /** 战斗开始 */
  START = 0,
  /** 随从发起攻击 */
  ATTACK = 1,
  /** 造成伤害（数字飘字） */
  DAMAGE = 2,
  /** 圣盾抵消伤害 */
  SHIELD_BLOCK = 3,
  /** 随从死亡 */
  DEATH = 4,
  /** 亡语触发 */
  DEATHRATTLE = 5,
  /** 召唤新随从 */
  SUMMON = 6,
  /** 属性变化（攻击/血量） */
  STAT_CHANGE = 7,
  /** 复生触发 */
  REBORN_TRIGGER = 8,
  /** 战斗结束 */
  END = 9,
  /** 英雄受到伤害 */
  HERO_DAMAGE = 10
}

/** 单条战斗事件 */
export interface CombatEvent {
  type: CombatEventType;
  /** 主动方 uid（攻击者/触发者），无则为 -1 */
  actorUid: number;
  /** 主动方阵营 */
  actorSide: Side;
  /** 被动方 uid（被攻击/被影响），无则为 -1 */
  targetUid: number;
  /** 被动方阵营 */
  targetSide: Side;
  /** 数值（伤害量、属性变化等） */
  amount: number;
  /** 文字描述（如亡语效果） */
  text: string;
  /** 效果结算后的独立状态：召唤含 defId，复生保留 actorUid。 */
  minionState?: Minion;
  atkDelta?: number;
  hpDelta?: number;
}

/** 战斗结果 */
export enum BattleOutcome {
  PLAYER_WIN = 0,
  AI_WIN = 1,
  DRAW = 2
}

/** 一次完整战斗的产出：事件序列 + 结果 + 双方剩余场面 */
export class BattleResult {
  events: CombatEvent[] = [];
  outcome: BattleOutcome = BattleOutcome.DRAW;
  /** 玩家剩余随从总攻击力（用于计算对英雄伤害） */
  playerRemainingAtk: number = 0;
  /** AI 剩余随从总攻击力 */
  aiRemainingAtk: number = 0;
  /** 玩家受到的伤害（败则 = aiRemainingAtk + 酒馆等级，平局为 0） */
  playerDamageTaken: number = 0;
  /** AI 受到的伤害 */
  aiDamageTaken: number = 0;
  /** 战斗开始时玩家的随从（用于回放展示初始阵容） */
  playerInit: Minion[] = [];
  /** 战斗开始时 AI 的随从 */
  aiInit: Minion[] = [];
}

/** 工厂：便捷构造事件 */
export function ev(type: CombatEventType, actorUid: number, actorSide: Side,
  targetUid: number = -1, targetSide: Side = Side.AI,
  amount: number = 0, text: string = ''): CombatEvent {
  return {
    type, actorUid, actorSide, targetUid, targetSide, amount, text
  };
}
