/**
 * 酒馆战棋 - 触发时机与效果模型
 *
 * 炉石战棋的核心是"触发式"能力：随从在特定时机（被卖出、被攻击、回合开始等）
 * 自动产生效果。这里把"时机"和"效果"抽象成枚举，让卡牌库可以声明式地描述能力，
 * 引擎再统一调度。这样的设计让新增卡牌只需声明触发点，而无需改动引擎主循环。
 */

/** 触发时机：随从能力生效的事件点 */
export enum Trigger {
  /** 战吼：从手牌打出时立即触发一次 */
  BATTLECRY = 0,
  /** 亡语：随从死亡时触发 */
  ON_DEATH = 1,
  /** 回合开始：每个准备回合开始时 */
  ON_TURN_START = 2,
  /** 友方随从死亡时（食腐、机械套件类） */
  ON_ALLY_DEATH = 3,
  /** 自己受到伤害后（狂暴/激怒类） */
  ON_SELF_DAMAGED = 4,
  /** 攻击后（激励/荣誉类） */
  ON_ATTACK = 5,
  /** 战斗开始时（光环/起手效果） */
  ON_COMBAT_START = 6,
  /** 持续光环：战斗中持续生效（如给相邻随从加属性） */
  AURA = 7
}

/** 效果类型：触发后做什么 */
export enum EffectType {
  /** 给自身或目标加攻击力/生命值 */
  BUFF_STATS = 0,
  /** 召唤一个随从到战场上 */
  SUMMON = 1,
  /** 对一个随从造成伤害 */
  DAMAGE = 2,
  /** 获得/给与金币 */
  COIN = 3,
  /** 抽一张牌到手中 */
  DRAW = 4,
  /** 给予圣盾 */
  GIVE_DIVINE_SHIELD = 5,
  /** 给予嘲讽 */
  GIVE_TAUNT = 6,
  /** 给予风怒 */
  GIVE_WINDFURY = 7,
  /** 复活/复活某随从 */
  REVIVE = 8
}

/** 效果的目标选择方式 */
export enum TargetMode {
  /** 自己 */
  SELF = 0,
  /** 随机友方随从 */
  RANDOM_FRIENDLY = 1,
  /** 随机敌方随从 */
  RANDOM_ENEMY = 2,
  /** 相邻友方随从 */
  ADJACENT_ALLY = 3,
  /** 所有友方随从 */
  ALL_FRIENDLY = 4,
  /** 所有友方同种族随从 */
  SAME_TRIBE = 5,
  /** 最高攻敌方随从 */
  HIGHEST_ATTACK_ENEMY = 6,
  /** 所有敌方随从 */
  ALL_ENEMY = 7,
  /** 不需要目标（自身属性固定增益） */
  NONE = 8
}

/**
 * 效果描述：把"做什么 + 多少 + 给谁"打包成一个可序列化的数据。
 * atkDelta / hpDelta 为正表示增益，为负表示伤害/削减。
 * value 用于通用数值（如召唤几个、抽几张）。
 */
export interface EffectData {
  type: EffectType;
  target: TargetMode;
  /** 攻击力变化 */
  atkDelta: number;
  /** 生命值变化 */
  hpDelta: number;
  /** 通用数值参数（数量等） */
  value: number;
  /** 当效果为召唤时，指定召唤出的随从定义 id；否则为 -1 */
  summonId: number;
}

/**
 * 一个"触发器"：把"何时触发"和"触发后执行哪些效果"绑定在一起。
 * 一张随从卡可拥有多个触发器（例如既有亡语又有光环）。
 */
export interface TriggerDef {
  trigger: Trigger;
  effects: EffectData[];
}

/**
 * 工厂函数：构造一个简单的"属性增益"效果，避免重复样板代码。
 */
export function buff(target: TargetMode, atk: number, hp: number): EffectData {
  return {
    type: EffectType.BUFF_STATS,
    target: target,
    atkDelta: atk,
    hpDelta: hp,
    value: 0,
    summonId: -1
  };
}

/**
 * 工厂函数：构造一个召唤效果。
 */
export function summon(target: TargetMode, minionId: number, count: number): EffectData {
  return {
    type: EffectType.SUMMON,
    target: target,
    atkDelta: 0,
    hpDelta: 0,
    value: count,
    summonId: minionId
  };
}

/**
 * 工厂函数：构造一个伤害效果。
 */
export function damage(target: TargetMode, amount: number): EffectData {
  return {
    type: EffectType.DAMAGE,
    target: target,
    atkDelta: 0,
    hpDelta: -amount,
    value: amount,
    summonId: -1
  };
}

/**
 * 工厂函数：构造一个给关键词的效果。
 */
export function grantKeyword(target: TargetMode, type: EffectType): EffectData {
  return {
    type: type,
    target: target,
    atkDelta: 0,
    hpDelta: 0,
    value: 1,
    summonId: -1
  };
}
