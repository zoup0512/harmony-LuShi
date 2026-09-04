/**
 * 酒馆战棋 - 随从卡牌库
 *
 * 收录炉石酒馆战棋各等级、各种族代表性随从（命名略改避免商标，机制忠于原作）。
 * 每条记录用 MinionDef 实例 + 显式字段赋值的方式声明，符合 ArkTS 严格类型规则。
 * 卡牌按 tier（1-6）分级，商店刷新时只从"当前酒馆等级及以下"的池中抽取。
 * 金色（三连）版本不在此列出，运行时由引擎把 Def 数值翻倍生成。
 */

import { MinionDef } from '../model/Minion';
import { Keyword, Tribe } from '../model/Types';
import { Trigger, TriggerDef, EffectData, EffectType, TargetMode } from '../model/Trigger';

/** 全局自增 id 生成（库加载时按顺序赋值） */
let NEXT_ID = 1000;

/** 工厂：创建一个 MinionDef 并赋 id */
function makeDef(name: string, atk: number, hp: number, tier: number, tribe: Tribe): MinionDef {
  const def = new MinionDef();
  def.id = NEXT_ID++;
  def.name = name;
  def.atk = atk;
  def.hp = hp;
  def.tier = tier;
  def.tribe = tribe;
  return def;
}

/** 构造一个触发器 */
function trig(trigger: Trigger, effects: EffectData[]): TriggerDef {
  const t: TriggerDef = { trigger: trigger, effects: effects };
  return t;
}

/** 构造 buff 效果 */
function buff(target: TargetMode, atk: number, hp: number): EffectData {
  const e: EffectData = {
    type: EffectType.BUFF_STATS, target: target,
    atkDelta: atk, hpDelta: hp, value: 0, summonId: -1
  };
  return e;
}

/** 构造召唤效果 */
function summon(target: TargetMode, minionId: number, count: number): EffectData {
  const e: EffectData = {
    type: EffectType.SUMMON, target: target,
    atkDelta: 0, hpDelta: 0, value: count, summonId: minionId
  };
  return e;
}

/** 构造伤害效果 */
function damage(target: TargetMode, amount: number): EffectData {
  const e: EffectData = {
    type: EffectType.DAMAGE, target: target,
    atkDelta: 0, hpDelta: -amount, value: amount, summonId: -1
  };
  return e;
}

/** 构造给予关键词的效果 */
function grantKeyword(target: TargetMode, type: EffectType): EffectData {
  const e: EffectData = {
    type: type, target: target,
    atkDelta: 0, hpDelta: 0, value: 1, summonId: -1
  };
  return e;
}

// ============================== Tier 1 ==============================

/** 鱼人招潮者：每回合开始时使一个随机友方鱼人 +1/+1 */
const MURLOC_TIDECALLER: MinionDef = makeDef('招潮者', 1, 2, 1, Tribe.MURLOC);
MURLOC_TIDECALLER.flavor = '每当有友方鱼人登场，便壮一分。';
MURLOC_TIDECALLER.triggers = [trig(Trigger.ON_TURN_START, [buff(TargetMode.SAME_TRIBE, 1, 1)])];

/** 微型机械：1/1 衍生物 */
const MICROBOT: MinionDef = makeDef('微型机械', 1, 1, 1, Tribe.MECH);
MICROBOT.flavor = '蜂群战术的最小单元。';

/** 损坏傀儡：亡语召唤一个 1/1 机械 */
const DAMAGED_GOLEM: MinionDef = makeDef('损坏傀儡', 2, 1, 1, Tribe.MECH);
DAMAGED_GOLEM.keywords = [Keyword.DEATHRATTLE];
DAMAGED_GOLEM.flavor = '亡语：召唤一个 1/1 的微型机械。';
DAMAGED_GOLEM.triggers = [trig(Trigger.ON_DEATH, [summon(TargetMode.SELF, MICROBOT.id, 1)])];

/** 银卫侍从：嘲讽挡刀 */
const ARTHAS_GUARD: MinionDef = makeDef('银卫侍从', 1, 4, 1, Tribe.NEUTRAL);
ARTHAS_GUARD.keywords = [Keyword.TAUNT];
ARTHAS_GUARD.flavor = '为王而盾，寸步不退。';

/** 火焰小鬼：战吼对随机敌方造成 1 伤害 */
const IMP: MinionDef = makeDef('火焰小鬼', 3, 2, 1, Tribe.DEMON);
IMP.flavor = '战吼：对一个随机敌方随从造成 1 点伤害。';
IMP.triggers = [trig(Trigger.BATTLECRY, [damage(TargetMode.RANDOM_ENEMY, 1)])];

/** 幼年红龙：2/3 龙族种子 */
const WHELPLING: MinionDef = makeDef('幼年红龙', 2, 3, 1, Tribe.DRAGON);
WHELPLING.flavor = '尚不知恐惧为何物。';

/** 猎潮鱼人：2/1 鱼人快攻 */
const MURLOC_HUNTER: MinionDef = makeDef('猎潮鱼人', 2, 1, 1, Tribe.MURLOC);
MURLOC_HUNTER.flavor = '潮水所至，皆为其猎场。';

/** 草原狼：每回合开始 +1 攻击 */
const PRAIRIE_WOLF: MinionDef = makeDef('草原狼', 1, 1, 1, Tribe.BEAST);
PRAIRIE_WOLF.flavor = '群居而凶猛，越饿越快。';
PRAIRIE_WOLF.triggers = [trig(Trigger.ON_TURN_START, [buff(TargetMode.SELF, 1, 0)])];

// ============================== Tier 2 ==============================

/** 幼熊：1/2 嘲讽衍生物 */
const CUB: MinionDef = makeDef('幼熊', 1, 2, 2, Tribe.BEAST);
CUB.keywords = [Keyword.TAUNT];
CUB.flavor = '母熊的孩子，同样不好惹。';

/** 母熊：3/3 嘲讽，亡语召唤 1/2 幼熊 */
const MOTHER_BEAR: MinionDef = makeDef('母熊', 3, 3, 2, Tribe.BEAST);
MOTHER_BEAR.keywords = [Keyword.TAUNT, Keyword.DEATHRATTLE];
MOTHER_BEAR.flavor = '亡语：召唤一只 1/2 的嘲讽幼熊。';
MOTHER_BEAR.triggers = [trig(Trigger.ON_DEATH, [summon(TargetMode.SELF, CUB.id, 1)])];

/** 地精技师：战吼给友方机械 +1/+1 */
const MECHANIC: MinionDef = makeDef('地精技师', 2, 2, 2, Tribe.MECH);
MECHANIC.flavor = '战吼：使一个随机友方机械 +1/+1。';
MECHANIC.triggers = [trig(Trigger.BATTLECRY, [buff(TargetMode.SAME_TRIBE, 1, 1)])];

/** 忘语咒师：回合开始获得圣盾 */
const AMNESIAC_MAGE: MinionDef = makeDef('忘语咒师', 2, 2, 2, Tribe.ELEMENTAL);
AMNESIAC_MAGE.flavor = '回合开始：获得圣盾。';
AMNESIAC_MAGE.triggers = [trig(Trigger.ON_TURN_START,
  [grantKeyword(TargetMode.SELF, EffectType.GIVE_DIVINE_SHIELD)])];

/** 嗜血鱼人：回合开始使所有友方鱼人 +1 攻击 */
const BLOODSAIL_MURLOC: MinionDef = makeDef('嗜血鱼人', 2, 2, 2, Tribe.MURLOC);
BLOODSAIL_MURLOC.flavor = '回合开始：使所有友方鱼人 +1 攻击力。';
BLOODSAIL_MURLOC.triggers = [trig(Trigger.ON_TURN_START, [buff(TargetMode.SAME_TRIBE, 1, 0)])];

/** 恶魔门徒：2/4 身材怪 */
const DEMON_DISCIPLE: MinionDef = makeDef('恶魔门徒', 2, 4, 2, Tribe.DEMON);
DEMON_DISCIPLE.flavor = '它的存在本身就是诅咒。';

/** 龙人执行者：光环给相邻龙 +1 攻击 */
const DRAGON_EXECUTOR: MinionDef = makeDef('龙人执行者', 3, 2, 2, Tribe.DRAGON);
DRAGON_EXECUTOR.flavor = '光环：相邻的龙获得 +1 攻击力。';
DRAGON_EXECUTOR.triggers = [trig(Trigger.AURA, [buff(TargetMode.ADJACENT_ALLY, 1, 0)])];

/** 劫掠海盗：4/1 风怒 */
const PIRATE_RAIDER: MinionDef = makeDef('劫掠海盗', 4, 1, 2, Tribe.PIRATE);
PIRATE_RAIDER.keywords = [Keyword.WINDFURY];
PIRATE_RAIDER.flavor = '快刀两下，谁也躲不过。';

// ============================== Tier 3 ==============================

/** 钴蓝卫士：6/3 圣盾机械 */
const COBALT_GUARDIAN: MinionDef = makeDef('钴蓝卫士', 6, 3, 3, Tribe.MECH);
COBALT_GUARDIAN.keywords = [Keyword.DIVINE_SHIELD];
COBALT_GUARDIAN.flavor = '圣盾机械的标杆身材。';

/** 食腐土狼：友方野兽死亡 +2/+2 */
const SCAVENGING_HYENA: MinionDef = makeDef('食腐土狼', 2, 2, 3, Tribe.BEAST);
SCAVENGING_HYENA.flavor = '每当一个友方野兽死亡，便 +2/+2。';
SCAVENGING_HYENA.triggers = [trig(Trigger.ON_ALLY_DEATH, [buff(TargetMode.SELF, 2, 2)])];

/** 鱼人领袖：光环使所有友方鱼人 +1/+1 */
const MURLOC_WARLEADER: MinionDef = makeDef('鱼人领袖', 3, 3, 3, Tribe.MURLOC);
MURLOC_WARLEADER.flavor = '光环：使所有友方鱼人 +1/+1。';
MURLOC_WARLEADER.triggers = [trig(Trigger.AURA, [buff(TargetMode.SAME_TRIBE, 1, 1)])];

/** 归来恶魔：4/2 复生 */
const REBORN_DEMON: MinionDef = makeDef('归来恶魔', 4, 2, 3, Tribe.DEMON);
REBORN_DEMON.keywords = [Keyword.REBORN];
REBORN_DEMON.flavor = '死亡不过是它的一个小憩。';

/** 龙息术士：战吼对所有敌方造成 1 伤害 */
const DRAGON_BREATH: MinionDef = makeDef('龙息术士', 4, 4, 3, Tribe.ELEMENTAL);
DRAGON_BREATH.flavor = '战吼：对所有敌方随从造成 1 点伤害。';
DRAGON_BREATH.triggers = [trig(Trigger.BATTLECRY, [damage(TargetMode.ALL_ENEMY, 1)])];

/** 顺劈战狂：4/3 顺劈 */
const CLEAVE_BERSERKER: MinionDef = makeDef('顺劈战狂', 4, 3, 3, Tribe.PIRATE);
CLEAVE_BERSERKER.keywords = [Keyword.CLEAVE];
CLEAVE_BERSERKER.flavor = '一刀三斩，前后夹击皆不放过。';

// ============================== Tier 4 ==============================

/** 机械巨兽：6/6 圣盾嘲讽机械 */
const MEGA_MECH: MinionDef = makeDef('机械巨兽', 6, 6, 4, Tribe.MECH);
MEGA_MECH.keywords = [Keyword.DIVINE_SHIELD, Keyword.TAUNT];
MEGA_MECH.flavor = '钢铁洪流的尖兵。';

/** 鸦人先知：回合开始给随机友方圣盾 */
const RAVEN_PROPHET: MinionDef = makeDef('鸦人先知', 2, 4, 4, Tribe.BEAST);
RAVEN_PROPHET.flavor = '回合开始：使一个随机友方随从获得圣盾。';
RAVEN_PROPHET.triggers = [trig(Trigger.ON_TURN_START,
  [grantKeyword(TargetMode.RANDOM_FRIENDLY, EffectType.GIVE_DIVINE_SHIELD)])];

/** 红龙女王：光环给所有龙 +2/+2 */
const DRAGON_QUEEN: MinionDef = makeDef('红龙女王', 6, 7, 4, Tribe.DRAGON);
DRAGON_QUEEN.flavor = '光环：使所有友方龙 +2/+2。';
DRAGON_QUEEN.triggers = [trig(Trigger.AURA, [buff(TargetMode.SAME_TRIBE, 2, 2)])];

/** 剧毒蝎：2/3 剧毒 */
const POISON_SCORPID: MinionDef = makeDef('剧毒蝎', 2, 3, 4, Tribe.BEAST);
POISON_SCORPID.keywords = [Keyword.POISONOUS];
POISON_SCORPID.flavor = '一蜇封喉，再大的家伙也得分崩。';

/** 暗影术士：4/5，亡语召唤两个 1/1 小鬼 */
const SHADOW_WARLOCK: MinionDef = makeDef('暗影术士', 4, 5, 4, Tribe.DEMON);
SHADOW_WARLOCK.keywords = [Keyword.DEATHRATTLE];
SHADOW_WARLOCK.flavor = '亡语：召唤两个 1/1 小鬼。';
SHADOW_WARLOCK.triggers = [trig(Trigger.ON_DEATH, [summon(TargetMode.SELF, IMP.id, 2)])];

// ============================== Tier 5 ==============================

/** 麦克斯纳：2/7 剧毒风怒 */
const MAEXXNA: MinionDef = makeDef('麦克斯纳', 2, 7, 5, Tribe.BEAST);
MAEXXNA.keywords = [Keyword.POISONOUS, Keyword.WINDFURY];
MAEXXNA.flavor = '蛛网之下，皆为亡魂。';

/** 三花机甲：9/4 圣盾嘲讽机械 */
const TRIPLE_MECH: MinionDef = makeDef('三花机甲', 9, 4, 5, Tribe.MECH);
TRIPLE_MECH.keywords = [Keyword.DIVINE_SHIELD, Keyword.TAUNT];
TRIPLE_MECH.flavor = '三倍装甲，三倍信念。';

/** 烬鳞巨龙：光环给所有龙 +3/+3 */
const EMBERSCALE: MinionDef = makeDef('烬鳞巨龙', 7, 7, 5, Tribe.DRAGON);
EMBERSCALE.flavor = '光环：使所有友方龙 +3/+3。';
EMBERSCALE.triggers = [trig(Trigger.AURA, [buff(TargetMode.SAME_TRIBE, 3, 3)])];

/** 灵魂歌者：5/5，亡语召唤两个 2/4 恶魔 */
const SOUL_SINGER: MinionDef = makeDef('灵魂歌者', 5, 5, 5, Tribe.DEMON);
SOUL_SINGER.keywords = [Keyword.DEATHRATTLE];
SOUL_SINGER.flavor = '亡语：召唤两个 2/4 的恶魔门徒。';
SOUL_SINGER.triggers = [trig(Trigger.ON_DEATH, [summon(TargetMode.SELF, DEMON_DISCIPLE.id, 2)])];

// ============================== Tier 6 ==============================

/** 鱼人喽啰：1/1 衍生物 */
const MURLOC_KING_SUMMON: MinionDef = makeDef('鱼人喽啰', 1, 1, 6, Tribe.MURLOC);
MURLOC_KING_SUMMON.flavor = '为女王而生，为女王而战。';

/** 鱼人女王：回合开始召唤鱼人并使所有鱼人 +1/+1 */
const MURLOC_QUEEN: MinionDef = makeDef('鱼人女王', 4, 4, 6, Tribe.MURLOC);
MURLOC_QUEEN.flavor = '回合开始：召唤一个鱼人，并使所有鱼人 +1/+1。';
MURLOC_QUEEN.triggers = [trig(Trigger.ON_TURN_START, [
  summon(TargetMode.SELF, MURLOC_KING_SUMMON.id, 1),
  buff(TargetMode.SAME_TRIBE, 1, 1)
])];

/** 暴食机甲：8/8 圣盾风怒机械 */
const GLUTTON_MECH: MinionDef = makeDef('暴食机甲', 8, 8, 6, Tribe.MECH);
GLUTTON_MECH.keywords = [Keyword.DIVINE_SHIELD, Keyword.WINDFURY];
GLUTTON_MECH.flavor = '吞噬一切，包括时间。';

/** 死亡之翼：12/12 复生龙 */
const DEATHWING: MinionDef = makeDef('死亡之翼', 12, 12, 6, Tribe.DRAGON);
DEATHWING.keywords = [Keyword.REBORN];
DEATHWING.flavor = '终末之翼，遮天蔽日。';

/** 通用 1/1 衍生物（备用） */
const TOKEN_1_1: MinionDef = makeDef('小喽啰', 1, 1, 1, Tribe.NEUTRAL);
TOKEN_1_1.flavor = '炮灰也有它的价值。';

/**
 * 完整卡牌库（按 tier 排列便于商店抽取）。
 * 因为部分触发器引用了"后定义"的 id（如 DAMAGED_GOLEM 引用 MICROBOT），
 * 而 const 顶层声明按顺序执行，到 ALL_MINIONS 数组时所有 const 已赋值，id 可用。
 */
export const ALL_MINIONS: MinionDef[] = [
  // Tier 1
  MURLOC_TIDECALLER, DAMAGED_GOLEM, ARTHAS_GUARD, IMP, WHELPLING,
  MURLOC_HUNTER, PRAIRIE_WOLF, MICROBOT, TOKEN_1_1,
  // Tier 2
  MOTHER_BEAR, CUB, MECHANIC, AMNESIAC_MAGE, BLOODSAIL_MURLOC,
  DEMON_DISCIPLE, DRAGON_EXECUTOR, PIRATE_RAIDER,
  // Tier 3
  COBALT_GUARDIAN, SCAVENGING_HYENA, MURLOC_WARLEADER, REBORN_DEMON,
  DRAGON_BREATH, CLEAVE_BERSERKER,
  // Tier 4
  MEGA_MECH, RAVEN_PROPHET, DRAGON_QUEEN, POISON_SCORPID, SHADOW_WARLOCK,
  // Tier 5
  MAEXXNA, TRIPLE_MECH, EMBERSCALE, SOUL_SINGER,
  // Tier 6
  MURLOC_QUEEN, MURLOC_KING_SUMMON, GLUTTON_MECH, DEATHWING
];

/** id -> MinionDef 的查找表（运行时频繁查询） */
export const MINION_BY_ID: Map<number, MinionDef> = new Map<number, MinionDef>();
for (const m of ALL_MINIONS) {
  MINION_BY_ID.set(m.id, m);
}

/** 取一个 Def 的金色（三连）版本：数值翻倍，触发器效果也翻倍。 */
export function goldenVersion(def: MinionDef): MinionDef {
  const g = new MinionDef();
  g.id = def.id;
  g.name = def.name;
  g.atk = def.atk * 2;
  g.hp = def.hp * 2;
  g.tier = def.tier;
  g.tribe = def.tribe;
  g.keywords = def.keywords.slice();
  g.golden = true;
  g.flavor = '★金色★ ' + def.flavor;
  // 触发器效果数值翻倍
  const newTriggers: TriggerDef[] = [];
  for (const t of def.triggers) {
    const newEffects: EffectData[] = [];
    for (const e of t.effects) {
      const ne: EffectData = {
        type: e.type,
        target: e.target,
        atkDelta: e.atkDelta * 2,
        hpDelta: e.hpDelta * 2,
        value: e.value * 2,
        summonId: e.summonId
      };
      newEffects.push(ne);
    }
    newTriggers.push(trig(t.trigger, newEffects));
  }
  g.triggers = newTriggers;
  return g;
}
