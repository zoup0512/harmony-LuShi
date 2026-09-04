/**
 * 酒馆战棋 - 随从模型
 *
 * MinionDef 是一张随从的"蓝图"（静态定义，从卡牌库读取）；
 * Minion 是这个蓝图在战场/商店上的一份"实例"（带当前血量、圣盾、强化标记等可变状态）。
 *
 * 战棋里"三连"会把三张同名同星级随从升级成一张金色（星级 +1）随从，因此 Minion
 * 需要记录 tier 和 golden 标记；同时为复用同一份 Def，Minion 会保留自身的
 * 当前攻击力/生命值（可能因增益而与 Def 的基础值不同）。
 */

import { Keyword, Tribe } from './Types';
import { TriggerDef } from './Trigger';

/** 随从静态定义（卡牌库中的一条记录） */
export class MinionDef {
  /** 全局唯一 id（卡牌库内自增） */
  id: number = 0;
  /** 显示名 */
  name: string = '';
  /** 基础攻击力 */
  atk: number = 1;
  /** 基础生命值 */
  hp: number = 1;
  /** 出现的酒馆等级（1-6） */
  tier: number = 1;
  /** 种族 */
  tribe: Tribe = Tribe.NEUTRAL;
  /** 持有的关键词 */
  keywords: Keyword[] = [];
  /** 触发能力列表（亡语/光环等） */
  triggers: TriggerDef[] = [];
  /** 简短风味文字（用于 UI） */
  flavor: string = '';
  /** 是否为金色（三连产物） */
  golden: boolean = false;

  constructor(init?: Partial<MinionDef>) {
    if (init) {
      if (init.id !== undefined) this.id = init.id;
      if (init.name !== undefined) this.name = init.name;
      if (init.atk !== undefined) this.atk = init.atk;
      if (init.hp !== undefined) this.hp = init.hp;
      if (init.tier !== undefined) this.tier = init.tier;
      if (init.tribe !== undefined) this.tribe = init.tribe;
      if (init.keywords !== undefined) this.keywords = init.keywords;
      if (init.triggers !== undefined) this.triggers = init.triggers;
      if (init.flavor !== undefined) this.flavor = init.flavor;
      if (init.golden !== undefined) this.golden = init.golden;
    }
  }
}

/** 战场上的随从实例（可变状态） */
export class Minion {
  /** 实例唯一 id（运行时区分同名实例） */
  uid: number;
  /** 引用的定义 id（用于查 Def 与展示） */
  defId: number;
  /** 当前攻击力 */
  atk: number;
  /** 当前生命值 */
  hp: number;
  /** 当前最大生命值（用于复生/治疗上限） */
  maxHp: number;
  /** 持有的关键词（运行时可变，例如获得圣盾） */
  keywords: Set<Keyword>;
  /** 星级（1=普通，2=金色三连） */
  golden: boolean;
  /** 本回合剩余攻击次数（风怒=2） */
  attacksLeft: number;
  /** 本回合是否已经行动过（用于排序） */
  acted: boolean = false;
  /** 临时伤害标记（剧毒等结算用） */
  pendingDestroy: boolean = false;

  constructor(def: MinionDef, uid: number) {
    this.uid = uid;
    this.defId = def.id;
    this.atk = def.atk;
    this.hp = def.hp;
    this.maxHp = def.hp;
    this.keywords = new Set<Keyword>(def.keywords);
    this.golden = def.golden;
    this.attacksLeft = this.hasKeyword(Keyword.WINDFURY) ? 2 : 1;
  }

  hasKeyword(k: Keyword): boolean {
    return this.keywords.has(k);
  }

  addKeyword(k: Keyword): void {
    this.keywords.add(k);
  }

  removeKeyword(k: Keyword): void {
    this.keywords.delete(k);
  }

  /** 复制一份实例（用于把商店随从克隆到战场） */
  clone(newUid: number): Minion {
    const m = new Minion(MinionDef.empty(), newUid);
    m.defId = this.defId;
    m.atk = this.atk;
    m.hp = this.hp;
    m.maxHp = this.maxHp;
    m.keywords = new Set<Keyword>(this.keywords);
    m.golden = this.golden;
    m.attacksLeft = this.attacksLeft;
    m.acted = this.acted;
    m.pendingDestroy = this.pendingDestroy;
    return m;
  }
}

/** 给 MinionDef 一个空构造用的占位（clone 时使用） */
export module MinionDef {
  export function empty(): MinionDef {
    return new MinionDef();
  }
}
