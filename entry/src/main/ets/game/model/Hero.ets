/**
 * 酒馆战棋 - 英雄模型
 *
 * 英雄决定玩家初始血量与一个"英雄技能"。技能是每个准备回合可花费金币使用的
 * 主动效果（区别于随从的被动触发）。为简化引擎，技能效果复用随从的 EffectData 表达。
 */

import { EffectData } from './Trigger';
import { Minion } from './Minion';

/** 英雄技能的目标选择（沿用随从的 TargetMode，但英雄技能更常用"全场/自己"） */
export enum HeroSkillTarget {
  /** 无目标：纯属性/经济效果 */
  NONE = 0,
  /** 自己场上随机随从 */
  SELF_RANDOM_MINION = 1,
  /** 自己场上所有随从 */
  SELF_ALL_MINION = 2,
  /** 商店里刷新（替换当前商店） */
  REFRESH_SHOP = 3,
  /** 获得某个关键词给随机友方 */
  GIVE_KEYWORD = 4
}

/** 英雄技能定义 */
export interface HeroSkill {
  /** 技能名 */
  name: string;
  /** 一次性使用花费（多数为 1-2 金币） */
  cost: number;
  /** 效果数据（复用随从效果结构） */
  effect: EffectData;
  /** 目标语义 */
  target: HeroSkillTarget;
  /** 描述（UI 用） */
  desc: string;
}

/** 英雄定义 */
export class HeroDef {
  id: number = 0;
  name: string = '';
  /** 英雄技能 */
  skill: HeroSkill | null = null;
  /** 初始血量 */
  baseHealth: number = 40;
  /** 技能图标符号（emoji/字符，UI 用） */
  icon: string = '⚔';
  /** 主题色（卡片背景） */
  color: string = '#7B5E3B';

  constructor(init?: Partial<HeroDef>) {
    if (init) {
      if (init.id !== undefined) this.id = init.id;
      if (init.name !== undefined) this.name = init.name;
      if (init.skill !== undefined) this.skill = init.skill;
      if (init.baseHealth !== undefined) this.baseHealth = init.baseHealth;
      if (init.icon !== undefined) this.icon = init.icon;
      if (init.color !== undefined) this.color = init.color;
    }
  }
}

/** 玩家（含人类与 AI）的运行时状态 */
export class PlayerState {
  /** 英雄定义 */
  hero: HeroDef;
  /** 当前血量 */
  health: number;
  /** 当前金币 */
  gold: number;
  /** 酒馆等级 1-6 */
  tavernTier: number;
  /** 升级到下一级所需金币（运行时计算） */
  upgradeCost: number;
  /** 刷新商店所需金币 */
  refreshCost: number;
  /** 战场随从（战斗时使用） */
  board: Minion[] = [];
  /** 商店可购买的随从 */
  shop: Minion[] = [];
  /** 手牌（购买后暂存，打出时上战场） */
  hand: Minion[] = [];
  /** 技能本回合是否已用 */
  skillUsed: boolean = false;

  constructor(hero: HeroDef) {
    this.hero = hero;
    this.health = hero.baseHealth;
    this.gold = 3;
    this.tavernTier = 1;
    this.upgradeCost = 5;
    this.refreshCost = 1;
  }
}
