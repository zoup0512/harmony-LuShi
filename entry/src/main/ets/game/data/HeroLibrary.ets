/**
 * 酒馆战棋 - 英雄卡牌库
 *
 * 每位英雄拥有一个可主动使用的技能。技能效果用 EffectData 描述，引擎统一调度。
 * 使用 HeroDef 实例 + 显式字段赋值，符合 ArkTS 严格类型规则。
 */

import { HeroDef, HeroSkill, HeroSkillTarget } from '../model/Hero';
import { EffectData, EffectType, TargetMode } from '../model/Trigger';

let NEXT_HERO_ID = 1;

function makeHero(name: string, icon: string, color: string, baseHealth: number): HeroDef {
  const h = new HeroDef();
  h.id = NEXT_HERO_ID++;
  h.name = name;
  h.icon = icon;
  h.color = color;
  h.baseHealth = baseHealth;
  return h;
}

function makeSkill(name: string, cost: number, target: HeroSkillTarget, desc: string,
  effect: EffectData): HeroSkill {
  const s: HeroSkill = {
    name: name, cost: cost, target: target, desc: desc, effect: effect
  };
  return s;
}

function buffEffect(target: TargetMode, atk: number, hp: number): EffectData {
  const e: EffectData = {
    type: EffectType.BUFF_STATS, target: target,
    atkDelta: atk, hpDelta: hp, value: 0, summonId: -1
  };
  return e;
}

function shieldEffect(target: TargetMode): EffectData {
  const e: EffectData = {
    type: EffectType.GIVE_DIVINE_SHIELD, target: target,
    atkDelta: 0, hpDelta: 0, value: 1, summonId: -1
  };
  return e;
}

/** 虚灵大盗拉法姆：技能刷新商店 */
const RAFAAM: HeroDef = makeHero('虚灵大盗拉法姆', '🎩', '#6B3FA0', 40);
RAFAAM.skill = makeSkill('偷天换日', 1, HeroSkillTarget.REFRESH_SHOP,
  '刷新酒馆，且本次刷新不消耗金币。', buffEffect(TargetMode.NONE, 0, 0));

/** 猩猩之王穆克拉：给随机友方 +1/+1 */
const MUKLA: HeroDef = makeHero('猩猩之王穆克拉', '🦍', '#8B5A2B', 40);
MUKLA.skill = makeSkill('一根香蕉', 1, HeroSkillTarget.SELF_RANDOM_MINION,
  '使一个随机友方随从 +1/+1。', buffEffect(TargetMode.RANDOM_FRIENDLY, 1, 1));

/** 永恒者诺兹多姆：使所有友方 +1/+1 */
const NOZDORMU: HeroDef = makeHero('永恒者诺兹多姆', '⏳', '#C9A227', 40);
NOZDORMU.skill = makeSkill('时间恩赐', 2, HeroSkillTarget.SELF_ALL_MINION,
  '使所有友方随从 +1/+1。', buffEffect(TargetMode.ALL_FRIENDLY, 1, 1));

/** 盗王艾德温：给随机友方 +2/+2 */
const EDWIN: HeroDef = makeHero('盗王艾德温', '🗡', '#2F4F4F', 40);
EDWIN.skill = makeSkill('盗贼灵感', 1, HeroSkillTarget.SELF_RANDOM_MINION,
  '使一个随机友方随从 +2/+2。', buffEffect(TargetMode.RANDOM_FRIENDLY, 2, 2));

/** 大领主弗丁：给随机友方圣盾 */
const TIRION: HeroDef = makeHero('大领主弗丁', '🛡', '#1E5BA8', 40);
TIRION.skill = makeSkill('圣光护体', 2, HeroSkillTarget.GIVE_KEYWORD,
  '使一个随机友方随从获得圣盾。', shieldEffect(TargetMode.RANDOM_FRIENDLY));

/** 巫妖王阿尔萨斯：给随机友方 +1/+1 */
const ARTHAS: HeroDef = makeHero('巫妖王阿尔萨斯', '💀', '#1A3A5C', 45);
ARTHAS.skill = makeSkill('凛冬之力', 1, HeroSkillTarget.SELF_RANDOM_MINION,
  '使一个随机友方随从 +1/+1。', buffEffect(TargetMode.RANDOM_FRIENDLY, 1, 1));

export const ALL_HEROES: HeroDef[] = [RAFAAM, MUKLA, NOZDORMU, EDWIN, TIRION, ARTHAS];

/** 随机挑选一位英雄（供 AI 用），返回一份拷贝避免共享引用 */
export function randomHero(): HeroDef {
  const idx = Math.floor(Math.random() * ALL_HEROES.length);
  const src = ALL_HEROES[idx];
  const copy = makeHero(src.name, src.icon, src.color, src.baseHealth);
  copy.id = src.id;
  copy.skill = src.skill;
  return copy;
}
