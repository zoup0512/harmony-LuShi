/**
 * 酒馆战棋 - 核心类型定义
 *
 * 定义随从种族、关键词能力、以及战斗相关的基础枚举。
 * 这些枚举作为游戏规则的基础词汇表，被卡牌库、引擎、战斗系统共同引用。
 */

/** 随从种族（酒馆战棋中的 minion type / tribe） */
export enum Tribe {
  /** 野兽 */
  BEAST = 0,
  /** 恶魔 */
  DEMON = 1,
  /** 机械 */
  MECH = 2,
  /** 龙 */
  DRAGON = 3,
  /** 鱼人 */
  MURLOC = 4,
  /** 元素 */
  ELEMENTAL = 5,
  /** 海盗 */
  PIRATE = 6,
  /** 中立（无种族，或称 全部） */
  NEUTRAL = 7
}

/** 关键词能力（保留酒馆战棋最具代表性的机制） */
export enum Keyword {
  /** 嘲讽：敌人必须先攻击嘲讽随从 */
  TAUNT = 0,
  /** 圣盾：免疫下一次伤害 */
  DIVINE_SHIELD = 1,
  /** 风怒：每回合可攻击两次 */
  WINDFURY = 2,
  /** 亡语：死亡时触发效果 */
  DEATHRATTLE = 3,
  /** 复生：死亡后以 1 点生命值复活一次 */
  REBORN = 4,
  /** 毒液：对受到其伤害的随从立即消灭 */
  POISONOUS = 5,
  /** 狂战（Cleave）：攻击时对相邻随从也造成伤害 */
  CLEAVE = 6
}

/** 战斗中随从所处的阵营 */
export enum Side {
  PLAYER = 0,
  AI = 1
}

/** 游戏阶段 */
export enum Phase {
  /** 主菜单 */
  MENU = 0,
  /** 准备阶段（购买/排兵布阵） */
  RECRUIT = 1,
  /** 战斗阶段（自动战斗） */
  COMBAT = 2,
  /** 游戏结束 */
  GAME_OVER = 3
}

/**
 * 把种族枚举转换为中文展示名。
 * 仅用于 UI 文案，不参与规则计算。
 */
export function tribeName(t: Tribe): string {
  switch (t) {
    case Tribe.BEAST: return '野兽';
    case Tribe.DEMON: return '恶魔';
    case Tribe.MECH: return '机械';
    case Tribe.DRAGON: return '龙';
    case Tribe.MURLOC: return '鱼人';
    case Tribe.ELEMENTAL: return '元素';
    case Tribe.PIRATE: return '海盗';
    default: return '中立';
  }
}

/**
 * 把关键词枚举转换为简短中文标签（用于卡牌 UI 徽章）。
 */
export function keywordShort(k: Keyword): string {
  switch (k) {
    case Keyword.TAUNT: return '嘲';
    case Keyword.DIVINE_SHIELD: return '盾';
    case Keyword.WINDFURY: return '风';
    case Keyword.DEATHRATTLE: return '亡';
    case Keyword.REBORN: return '生';
    case Keyword.POISONOUS: return '毒';
    case Keyword.CLEAVE: return '顺';
    default: return '';
  }
}

/**
 * 把关键词枚举转换为完整中文描述（用于详情/教学）。
 */
export function keywordFull(k: Keyword): string {
  switch (k) {
    case Keyword.TAUNT: return '嘲讽：敌方必须优先攻击此随从';
    case Keyword.DIVINE_SHIELD: return '圣盾：抵消下一次受到的伤害';
    case Keyword.WINDFURY: return '风怒：每回合可攻击两次';
    case Keyword.DEATHRATTLE: return '亡语：死亡时触发特殊效果';
    case Keyword.REBORN: return '复生：死亡后以 1 点生命复活一次';
    case Keyword.POISONOUS: return '剧毒：对受到伤害的随从立刻消灭';
    case Keyword.CLEAVE: return '顺劈：同时攻击相邻随从';
    default: return '';
  }
}
