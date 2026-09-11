/**
 * 酒馆战棋 - 自动战斗模拟器
 *
 * 把玩家与 AI 的战场快照传入，模拟一整场自动战斗，产出事件序列与结果。
 *
 * 战斗规则（忠实于炉石战棋）：
 * 1. 双方按"最左侧未行动随从优先攻击"轮流出手；先手由双方随从数与随机决定；
 * 2. 攻击者必须先打嘲讽（若有），否则随机选择敌方目标；
 * 3. 双方互相造成伤害：攻击力对撞，圣盾抵消一次伤害，剧毒直接消灭；
 * 4. 死亡的随从触发亡语（召唤/伤害/增益）；
 * 5. 复生随从死亡后以 1 血复活一次；
 * 6. 战斗结束时，根据存活随从计算对英雄的伤害。
 *
 * 引擎与 UI 解耦：所有变化以 CombatEvent 形式记录，供 UI 逐帧回放。
 */

import { Minion } from '../model/Minion';
import { Keyword, Side } from '../model/Types';
import { EffectData, EffectType, TargetMode, Trigger } from '../model/Trigger';
import { MINION_BY_ID, effectiveDefinition } from '../data/MinionLibrary';
import { Rng, nextUid } from '../util/Rng';
import {
  BattleOutcome, BattleResult, CombatEventType, ev
} from './CombatTypes';

/** 战斗中一个阵营的运行时状态（独立于 PlayerState，避免污染准备阶段数据） */
class CombatSide {
  minions: Minion[] = [];
  side: Side;

  constructor(minions: Minion[], side: Side) {
    // 深拷贝，避免战斗修改影响准备阶段
    this.minions = minions.map((m) => m.clone(nextUid()));
    this.side = side;
  }

  alive(): Minion[] {
    return this.minions.filter((m) => m.hp > 0 && !m.pendingDestroy);
  }

  hasTaunt(): boolean {
    return this.alive().some((m) => m.hasKeyword(Keyword.TAUNT));
  }
}

/**
 * 执行一场战斗。
 * @param playerBoard 玩家战场快照
 * @param aiBoard AI 战场快照
 * @param rng 随机源（可注入以便测试）
 */
export function simulateBattle(
  playerBoard: Minion[],
  aiBoard: Minion[],
  rng: Rng = new Rng()
): BattleResult {
  const result = new BattleResult();
  const player = new CombatSide(playerBoard, Side.PLAYER);
  const ai = new CombatSide(aiBoard, Side.AI);

  result.playerInit = player.minions.map((m) => m.clone(m.uid));
  result.aiInit = ai.minions.map((m) => m.clone(m.uid));

  // 战斗开始事件
  result.events.push(ev(CombatEventType.START, -1, Side.PLAYER, -1, Side.AI, 0, '战斗开始'));

  // 应用光环（如给相邻/同族加属性）——战斗开始时一次性结算
  applyAuras(player, ai, result, rng);
  cleanupDeaths(player, ai, result, rng);

  // 决定先手：随从多的一方先手；相同则随机
  let attackerSide: Side;
  if (player.alive().length > ai.alive().length) {
    attackerSide = Side.PLAYER;
  } else if (ai.alive().length > player.alive().length) {
    attackerSide = Side.AI;
  } else {
    attackerSide = rng.next() < 0.5 ? Side.PLAYER : Side.AI;
  }

  // 主循环：轮流攻击，直到一方清场或达到最大回合数（防死循环）
  let iterations = 0;
  const MAX_ITER = 200;
  while (player.alive().length > 0 && ai.alive().length > 0 && iterations < MAX_ITER) {
    iterations++;
    const atkSide = attackerSide === Side.PLAYER ? player : ai;
    const defSide = attackerSide === Side.PLAYER ? ai : player;

    // 找一个还能攻击的随从（最左侧优先）
    const attacker = atkSide.alive().find((m) => m.attacksLeft > 0);
    if (!attacker) {
      // 没人能攻击，换边
      attackerSide = attackerSide === Side.PLAYER ? Side.AI : Side.PLAYER;
      // 重置本回合所有随从的攻击次数（换边时进入新"轮"）
      resetAttacks(atkSide);
      resetAttacks(defSide);
      continue;
    }

    performAttack(attacker, atkSide, defSide, result, rng);

    // 清理死亡随从（处理亡语、复生、移除）
    cleanupDeaths(player, ai, result, rng);

    // 该随从攻击次数 -1；若还有次数（风怒），同一方继续；否则换边
    attacker.attacksLeft--;
    if (attacker.attacksLeft <= 0 || attacker.hp <= 0) {
      attackerSide = attackerSide === Side.PLAYER ? Side.AI : Side.PLAYER;
    }
  }

  // 计算结果
  finishBattle(player, ai, result);
  return result;
}

/** 重置一方所有随从的攻击次数（用于换边） */
function resetAttacks(side: CombatSide): void {
  for (const m of side.alive()) {
    if (m.attacksLeft <= 0) {
      m.attacksLeft = m.hasKeyword(Keyword.WINDFURY) ? 2 : 1;
    }
  }
}

/**
 * 执行一次攻击：选择目标 → 造成伤害 → 触发反伤/亡语等。
 */
function performAttack(
  attacker: Minion, atkSide: CombatSide, defSide: CombatSide,
  result: BattleResult, rng: Rng
): void {
  // 选择目标
  const targets = defSide.alive();
  if (targets.length === 0) return;

  let target: Minion;
  const taunts = targets.filter((m) => m.hasKeyword(Keyword.TAUNT));
  if (taunts.length > 0) {
    target = rng.pick(taunts);
  } else {
    target = rng.pick(targets);
  }

  result.events.push(ev(
    CombatEventType.ATTACK, attacker.uid, atkSide.side, target.uid, defSide.side, 0,
    `攻击`
  ));

  // 顺劈：对目标及其相邻随从造成伤害
  const cleave = attacker.hasKeyword(Keyword.CLEAVE);
  const targetIdx = defSide.minions.indexOf(target);
  const hitTargets: Minion[] = [target];
  if (cleave && targetIdx >= 0) {
    if (targetIdx > 0) {
      const left = defSide.minions[targetIdx - 1];
      if (left.hp > 0) hitTargets.push(left);
    }
    if (targetIdx < defSide.minions.length - 1) {
      const right = defSide.minions[targetIdx + 1];
      if (right.hp > 0) hitTargets.push(right);
    }
  }

  // 攻击者对每个命中目标造成伤害（剧毒则标记消灭）
  for (const t of hitTargets) {
    dealDamage(attacker.atk, t, defSide, attacker, atkSide, result);
  }

  // 目标（主目标）反击攻击者
  if (target.hp > 0 || target.pendingDestroy) {
    dealDamage(target.atk, attacker, atkSide, target, defSide, result);
  } else {
    // 目标已死，仍然反击（炉石规则：双方同时造成伤害）
    dealDamage(target.atk, attacker, atkSide, target, defSide, result);
  }
}

/**
 * 对单个随从造成伤害，处理圣盾/剧毒/血量。
 * @param amount 伤害值
 * @param target 受伤随从
 * @param targetSide 受伤方
 * @param source 伤害来源（用于剧毒判定与亡语触发记录）
 * @param sourceSide 来源方
 */
function dealDamage(
  amount: number, target: Minion, targetSide: CombatSide,
  source: Minion, sourceSide: CombatSide, result: BattleResult
): void {
  if (amount <= 0 || target.hp <= 0) return;

  // 圣盾抵消
  if (target.hasKeyword(Keyword.DIVINE_SHIELD)) {
    target.removeKeyword(Keyword.DIVINE_SHIELD);
    result.events.push(ev(
      CombatEventType.SHIELD_BLOCK, target.uid, targetSide.side, -1, sourceSide.side, amount,
      '圣盾抵消'
    ));
    return;
  }

  target.hp -= amount;


  // 剧毒：来源带剧毒，目标血量 ≤0 后立即标记消灭
  if (source.hasKeyword(Keyword.POISONOUS) && target.hp > 0) {
    // 剧毒是"致命伤"，把目标血量直接置 0
    target.hp = 0;
  }

  if (target.hp <= 0) {
    target.hp = 0;
    target.pendingDestroy = true;
  }

  const event = ev(CombatEventType.DAMAGE, source.uid, sourceSide.side,
    target.uid, targetSide.side, amount, `受到 ${amount} 点伤害`);
  event.minionState = target.clone(target.uid);
  result.events.push(event);

  // 受伤触发（狂暴类）——简化为不实现，留扩展点
}

/** 非重入死亡批次：先移除双方死者，再触发效果；新死亡由下一批处理。
 * 保留简化复生规则（原实例原位置恢复 1 血，不先触发亡语）。
 */
function cleanupDeaths(
  side: CombatSide, opponent: CombatSide, result: BattleResult, rng: Rng
): void {
  while (true) {
    const sides: CombatSide[] = [side, opponent];
    const batches: Minion[][] = [];
    let found = false;
    for (const current of sides) {
      const dying = current.minions.filter((m) => m.pendingDestroy || m.hp <= 0);
      if (dying.length > 0) found = true;
      const dead: Minion[] = [];
      for (const m of dying) {
        if (m.hasKeyword(Keyword.REBORN)) {
          m.pendingDestroy = false;
          m.hp = 1;
          m.removeKeyword(Keyword.REBORN);
          const event = ev(CombatEventType.REBORN_TRIGGER, m.uid, current.side,
            -1, current.side, 0, '复生');
          event.minionState = m.clone(m.uid);
          result.events.push(event);
        } else {
          dead.push(m);
          result.events.push(ev(CombatEventType.DEATH, m.uid, current.side,
            -1, current.side, 0, '阵亡'));
        }
      }
      current.minions = current.minions.filter((m) => dead.indexOf(m) < 0);
      batches.push(dead);
    }
    if (!found) break;
    for (let i = 0; i < sides.length; i++) {
      const current = sides[i];
      const enemy = sides[1 - i];
      const dead = batches[i];
      for (const m of dead) triggerDeathrattles(m, current, enemy, result, rng);
      // 每个死者分别派发一次友方死亡回调，且亡语召唤物也能获得效果。
      for (const fallen of dead) {
        for (const ally of current.alive()) {
          resolveTriggers(ally, current, enemy, Trigger.ON_ALLY_DEATH, result, rng, [fallen]);
        }
      }
    }
  }
}

/**
 * 触发某随从的所有亡语效果。
 */
function triggerDeathrattles(
  owner: Minion, side: CombatSide, opponent: CombatSide,
  result: BattleResult, rng: Rng
): void {
  const def = effectiveDefinition(owner);
  if (!def) return;
  for (const trig of def.triggers) {
    if (trig.trigger !== Trigger.ON_DEATH) continue;
    result.events.push(ev(
      CombatEventType.DEATHRATTLE, owner.uid, side.side, -1, opponent.side, 0, '亡语触发'
    ));
    for (const eff of trig.effects) {
      resolveEffect(eff, owner, side, opponent, result, rng);
    }
  }
}

/**
 * 解析某随从在特定触发点的所有触发器，并对每个效果执行。
 */
function resolveTriggers(
  owner: Minion, side: CombatSide, opponent: CombatSide,
  trigger: Trigger, result: BattleResult, rng: Rng,
  context: Minion[] = []
): void {
  const def = effectiveDefinition(owner);
  if (!def) return;
  for (const trig of def.triggers) {
    if (trig.trigger !== trigger) continue;
    for (const eff of trig.effects) {
      resolveEffect(eff, owner, side, opponent, result, rng, context);
    }
  }
}

/**
 * 解析单个效果：选择目标 + 应用。
 * context 用于 ON_ALLY_DEATH 时传入刚死亡的随从（部分卡牌可能引用）。
 */
function resolveEffect(
  eff: EffectData, owner: Minion, side: CombatSide, opponent: CombatSide,
  result: BattleResult, rng: Rng, context: Minion[] = []
): void {
  // 召唤类
  if (eff.type === EffectType.SUMMON) {
    const count = eff.value; // 有效定义已翻倍
    const defId = eff.summonId;
    const def = MINION_BY_ID.get(defId);
    if (!def) return;
    for (let i = 0; i < count; i++) {
      if (side.alive().length >= 7) break;
      const newMinion = new Minion(def, nextUid());
      side.minions.push(newMinion);
      const event = ev(
        CombatEventType.SUMMON, owner.uid, side.side, newMinion.uid, side.side, 0,
        `召唤 ${def.name}`
      );
      event.minionState = newMinion.clone(newMinion.uid);
      result.events.push(event);
    }
    return;
  }

  // 选择目标
  const targets = selectTargets(eff.target, owner, side, opponent, rng);
  const atkDelta = eff.atkDelta;
  const hpDelta = eff.hpDelta;

  for (const t of targets) {
    const targetSide = opponent.minions.indexOf(t) >= 0 ? opponent : side;
    if (eff.type === EffectType.DAMAGE) {
      dealDamage(eff.value, t, targetSide, owner, side, result);
      continue;
    }
    let text = '';
    if (eff.type === EffectType.BUFF_STATS) {
      t.atk += atkDelta;
      t.hp += hpDelta;
      t.maxHp = Math.max(t.maxHp, t.hp);
      if (t.hp <= 0) t.pendingDestroy = true;
      text = `${atkDelta >= 0 ? '+' : ''}${atkDelta}/${hpDelta >= 0 ? '+' : ''}${hpDelta}`;
    } else if (eff.type === EffectType.GIVE_DIVINE_SHIELD) {
      t.addKeyword(Keyword.DIVINE_SHIELD);
      text = '获得圣盾';
    } else if (eff.type === EffectType.GIVE_TAUNT) {
      t.addKeyword(Keyword.TAUNT);
      text = '获得嘲讽';
    } else if (eff.type === EffectType.GIVE_WINDFURY) {
      t.addKeyword(Keyword.WINDFURY);
      text = '获得风怒';
    } else {
      continue;
    }
    const event = ev(CombatEventType.STAT_CHANGE, owner.uid, side.side,
      t.uid, targetSide.side, atkDelta, text);
    event.atkDelta = eff.type === EffectType.BUFF_STATS ? atkDelta : 0;
    event.hpDelta = eff.type === EffectType.BUFF_STATS ? hpDelta : 0;
    event.minionState = t.clone(t.uid);
    result.events.push(event);
  }
  // 不在效果内部清理；外层死亡 drain 处理连锁，避免重新触发同一死者。
}

/**
 * 根据目标模式选出受影响的随从列表。
 */
function selectTargets(
  mode: TargetMode, owner: Minion, side: CombatSide, opponent: CombatSide, rng: Rng
): Minion[] {
  const friendly = side.alive();
  const enemy = opponent.alive();
  const def = effectiveDefinition(owner);

  switch (mode) {
    case TargetMode.SELF:
      return owner.hp > 0 ? [owner] : [];
    case TargetMode.RANDOM_FRIENDLY:
      return friendly.length > 0 ? [rng.pick(friendly)] : [];
    case TargetMode.RANDOM_ENEMY:
      return enemy.length > 0 ? [rng.pick(enemy)] : [];
    case TargetMode.ADJACENT_ALLY: {
      const idx = side.minions.indexOf(owner);
      const res: Minion[] = [];
      if (idx > 0 && side.minions[idx - 1].hp > 0) res.push(side.minions[idx - 1]);
      if (idx >= 0 && idx < side.minions.length - 1 && side.minions[idx + 1].hp > 0) {
        res.push(side.minions[idx + 1]);
      }
      return res;
    }
    case TargetMode.ALL_FRIENDLY:
      return friendly;
    case TargetMode.SAME_TRIBE: {
      if (!def) return [];
      return friendly.filter((m) => {
        const d = effectiveDefinition(m);
        return d && d.tribe === def.tribe;
      });
    }
    case TargetMode.HIGHEST_ATTACK_ENEMY: {
      if (enemy.length === 0) return [];
      let max = enemy[0];
      for (const e of enemy) if (e.atk > max.atk) max = e;
      return [max];
    }
    case TargetMode.ALL_ENEMY:
      return enemy;
    default:
      return [];
  }
}

/**
 * 应用光环：战斗开始时一次性结算所有 AURA 触发器。
 * 光环在炉石中是"持续生效"，但这里简化为战斗开始时一次性加成（足够单机体验）。
 */
function applyAuras(
  player: CombatSide, ai: CombatSide, result: BattleResult, rng: Rng
): void {
  for (const side of [player, ai]) {
    const opponent = side === player ? ai : player;
    for (const m of side.alive()) {
      resolveTriggers(m, side, opponent, Trigger.AURA, result, rng);
    }
  }
}

/**
 * 战斗收尾：计算结果与英雄伤害。
 */
function finishBattle(player: CombatSide, ai: CombatSide, result: BattleResult): void {
  const pAlive = player.alive();
  const aAlive = ai.alive();

  result.playerRemainingAtk = pAlive.reduce((s, m) => s + m.atk, 0);
  result.aiRemainingAtk = aAlive.reduce((s, m) => s + m.atk, 0);

  if (pAlive.length > 0 && aAlive.length === 0) {
    result.outcome = BattleOutcome.PLAYER_WIN;
    // 对 AI 造成的伤害 = 存活随从总攻 + 当前酒馆等级（这里用存活数近似等级权重）
    result.aiDamageTaken = result.playerRemainingAtk + Math.min(pAlive.length, 6);
  } else if (aAlive.length > 0 && pAlive.length === 0) {
    result.outcome = BattleOutcome.AI_WIN;
    result.playerDamageTaken = result.aiRemainingAtk + Math.min(aAlive.length, 6);
  } else if (pAlive.length === 0 && aAlive.length === 0) {
    result.outcome = BattleOutcome.DRAW;
  } else {
    // 战斗回合耗尽但双方都有存活（罕见）：按总攻击力判胜负
    if (result.playerRemainingAtk > result.aiRemainingAtk) {
      result.outcome = BattleOutcome.PLAYER_WIN;
      result.aiDamageTaken = Math.max(1, result.playerRemainingAtk - result.aiRemainingAtk);
    } else if (result.aiRemainingAtk > result.playerRemainingAtk) {
      result.outcome = BattleOutcome.AI_WIN;
      result.playerDamageTaken = Math.max(1, result.aiRemainingAtk - result.playerRemainingAtk);
    } else {
      result.outcome = BattleOutcome.DRAW;
    }
  }

  result.events.push(ev(
    CombatEventType.END, -1, Side.PLAYER, -1, Side.AI, result.outcome,
    result.outcome === BattleOutcome.PLAYER_WIN ? '胜利' :
    result.outcome === BattleOutcome.AI_WIN ? '失败' : '平局'
  ));
}
