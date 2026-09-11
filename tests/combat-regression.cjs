// Run with Node >= 22.13: node --test tests/combat-regression.cjs
// Built-in TypeScript transformation only; no production dependencies or SDK changes.
const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const { stripTypeScriptTypes } = require('node:module');
const root = path.resolve(__dirname, '..');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'lushi-regression-'));
after(() => fs.rmSync(temp, { recursive: true, force: true }));
function compile(dir, out) {
  fs.mkdirSync(out, { recursive: true });
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const src = path.join(dir, entry.name);
    if (entry.isDirectory()) compile(src, path.join(out, entry.name));
    else if (entry.name.endsWith('.ets')) {
      // ArkTS accepts the legacy internal-module spelling; Node requires namespace.
      const source = fs.readFileSync(src, 'utf8').replace(/export module /g, 'export namespace ')
        .replace(/import\s*\{([^}]+)\}\s*from\s*(['"])(\.[^'"]+)\2;/g,
          (statement, names, quote, specifier) => {
            const dependency = fs.readFileSync(path.resolve(dir, specifier + '.ets'), 'utf8');
            const types = new Set([...dependency.matchAll(/export\s+(?:interface|type)\s+(\w+)/g)].map(m => m[1]));
            const values = names.split(',').map(n => n.trim()).filter(n => !types.has(n));
            return values.length ? `import { ${values.join(', ')} } from '${specifier}';` : '';
          });
      const js = stripTypeScriptTypes(source, { mode: 'transform' })
        .replace(/from\s+(['"])(\.[^'"]+)\1/g, 'from $1$2.mjs$1');
      fs.writeFileSync(path.join(out, entry.name.replace(/\.ets$/, '.mjs')), js);
    }
  }
}
compile(path.join(root, 'entry/src/main/ets/game'), temp);
const load = p => import(pathToFileURL(path.join(temp, p + '.mjs')).href);
const ready = Promise.all([
  load('combat/BattleSimulator'), load('combat/CombatTypes'), load('combat/ReplayReducer'),
  load('model/Minion'), load('model/Types'), load('model/Trigger'), load('data/MinionLibrary'),
  load('engine/GameEngine'), load('data/HeroLibrary'), load('util/Rng')
]).then(([sim, events, replay, model, types, trigger, library, engine, heroes, rng]) =>
  ({ ...sim, ...events, ...replay, ...model, ...types, ...trigger, ...library, ...engine, ...heroes, ...rng }));
let id = 90000;
function fixture(c, atk = 1, hp = 1, triggers = [], keywords = []) {
  const def = new c.MinionDef({ id: id++, atk, hp, triggers, keywords });
  c.MINION_BY_ID.set(def.id, def);
  return new c.Minion(def, c.nextUid());
}
function effect(c, type, target, value = 0, summonId = -1, atkDelta = 0, hpDelta = 0) {
  return { type, target, value, summonId, atkDelta, hpDelta };
}
function trigger(c, when, effects) { return { trigger: when, effects }; }
function named(c, name, golden = false) {
  const def = c.ALL_MINIONS.find(d => d.name === name);
  assert.ok(def, name);
  return new c.Minion(golden ? c.goldenVersion(def) : def, c.nextUid());
}
function run(c, p, a) { return c.simulateBattle(p, a, new c.Rng(123)); }
function deathsOnce(c, result) {
  const ids = result.events.filter(e => e.type === c.CombatEventType.DEATH).map(e => e.actorUid);
  assert.equal(new Set(ids).size, ids.length);
}

test('death + surviving ally buff drains without recursion, each death once', async () => {
  const c = await ready;
  const result = run(c, [fixture(c), named(c, '食腐土狼')], [fixture(c, 8, 30)]);
  deathsOnce(c, result);
  assert.ok(result.events.some(e => e.type === c.CombatEventType.STAT_CHANGE));
});
test('damage deathrattles chain across both sides and drain completely', async () => {
  const c = await ready;
  const blast = trigger(c, c.Trigger.ON_DEATH, [effect(c, c.EffectType.DAMAGE, c.TargetMode.ALL_ENEMY, 10)]);
  const result = run(c, [fixture(c, 1, 1, [blast]), fixture(c, 0, 1)], [fixture(c, 1, 1, [blast]), fixture(c, 0, 1)]);
  deathsOnce(c, result);
  assert.equal(result.events.filter(e => e.type === c.CombatEventType.DEATH).length, 4);
  assert.equal(result.outcome, c.BattleOutcome.DRAW);
  assert.ok(result.events.filter(e => e.type === c.CombatEventType.DAMAGE).every(e => e.actorSide !== e.targetSide));
});
test('each ally death in the same batch triggers surviving listeners once', async () => {
  const c = await ready;
  const listener = trigger(c, c.Trigger.ON_ALLY_DEATH,
    [effect(c, c.EffectType.BUFF_STATS, c.TargetMode.SELF, 0, -1, 2, 2)]);
  const result = run(c,
    [fixture(c, 0, 1), fixture(c, 0, 1), fixture(c, 1, 20, [listener])],
    [fixture(c, 10, 100)]);
  const listenerUid = result.playerInit[2].uid;
  const buffs = result.events.filter(e => e.type === c.CombatEventType.STAT_CHANGE &&
    e.targetUid === listenerUid);
  assert.equal(buffs.length, 2);
  assert.equal(buffs.reduce((sum, e) => sum + e.atkDelta, 0), 4);
});
test('full board frees dead slots before deathrattle summoning', async () => {
  const c = await ready;
  const golem = named(c, '损坏傀儡');
  const result = run(c, [golem, ...Array.from({ length: 6 }, () => fixture(c, 0, 100))], [fixture(c, 10, 1000)]);
  const owner = result.playerInit[0].uid;
  const summons = result.events.filter(e => e.type === c.CombatEventType.SUMMON && e.actorUid === owner);
  assert.equal(summons.length, 1);
  assert.equal(summons[0].minionState.uid, summons[0].targetUid);
});
test('golden helper doubles effects once without modifying base or instance', async () => {
  const c = await ready;
  const m = named(c, '招潮者', true);
  const base = c.MINION_BY_ID.get(m.defId);
  const def = c.effectiveDefinition(m);
  assert.equal(def.triggers[0].effects[0].atkDelta, 2);
  assert.equal(base.triggers[0].effects[0].atkDelta, 1);
  assert.equal(c.goldenVersion(def).atk, def.atk);
  assert.equal(m.atk, base.atk * 2);
  assert.equal(c.effectiveDefinition(m).atk, m.atk);
});
test('golden combat aura and deathrattle use effective definitions', async () => {
  const c = await ready;
  const aura = run(c, [named(c, '鱼人领袖', true)], []);
  assert.equal(aura.events.find(e => e.type === c.CombatEventType.STAT_CHANGE).atkDelta, 2);
  const summon = run(c, [named(c, '损坏傀儡', true)], [fixture(c, 30, 100)]);
  assert.equal(summon.events.filter(e => e.type === c.CombatEventType.SUMMON).length, 2);
});
test('golden turn-start buffs all friendly same tribe; golden battlecry applies once', async () => {
  const c = await ready;
  const engine = new c.GameEngine(c.ALL_HEROES[0], new c.Rng(1));
  const caller = named(c, '招潮者', true), ally = named(c, '猎潮鱼人'), other = named(c, '幼年红龙');
  engine.player.board = [caller, ally, other];
  const before = engine.player.board.map(m => m.atk);
  engine.startRecruitPhase();
  assert.deepEqual(engine.player.board.map((m, i) => m.atk - before[i]), [2, 2, 0]);
  const mech = named(c, '微型机械');
  engine.player.board = [mech];
  engine.player.shop = [named(c, '地精技师', true)];
  engine.player.gold = 10;
  assert.equal(engine.buyMinion(0), true);
  assert.equal(mech.atk, 3);
});
test('snapshots precede aura, share combat UIDs and remain isolated', async () => {
  const c = await ready;
  const source = named(c, '鱼人领袖');
  const result = run(c, [source], []);
  const change = result.events.find(e => e.type === c.CombatEventType.STAT_CHANGE);
  assert.equal(change.actorUid, result.playerInit[0].uid);
  assert.equal(change.targetUid, result.playerInit[0].uid);
  assert.equal(result.playerInit[0].atk, source.atk);
  assert.equal(change.minionState.atk, source.atk + 1);
  change.minionState.atk = 999;
  assert.equal(result.playerInit[0].atk, source.atk);
});
test('summons and reborn replay retain authoritative UID and state, ignoring text', async () => {
  const c = await ready;
  const result = run(c, [named(c, '损坏傀儡'), named(c, '归来恶魔', true)], [fixture(c, 5, 100)]);
  let p = c.replaySlots(result.playerInit), a = c.replaySlots(result.aiInit);
  let summons = 0, reborns = 0;
  for (const original of result.events) {
    const e = { ...original, text: 'unparseable localized display' };
    const previous = p;
    p = c.reduceReplay(p, c.Side.PLAYER, e);
    a = c.reduceReplay(a, c.Side.AI, e);
    assert.notEqual(p, previous);
    const slots = e.targetSide === c.Side.PLAYER ? p : a;
    if (e.type === c.CombatEventType.SUMMON) {
      summons++;
      assert.deepEqual(slots.find(s => s.minion.uid === e.targetUid).minion, e.minionState);
    }
    if (e.type === c.CombatEventType.REBORN_TRIGGER) {
      reborns++;
      const m = (e.actorSide === c.Side.PLAYER ? p : a).find(s => s.minion.uid === e.actorUid).minion;
      assert.equal(m.hp, 1);
      assert.equal(m.golden, true);
      assert.equal(m.hasKeyword(c.Keyword.REBORN), false);
      assert.equal(m.maxHp, e.minionState.maxHp);
    }
  }
  assert.ok(summons > 0 && reborns === 1);
  assert.equal(p.length, 0);
});
test('structured signed stat and keyword events replay exact maxHp without text parsing', async () => {
  const c = await ready;
  const aura = trigger(c, c.Trigger.AURA, [
    effect(c, c.EffectType.BUFF_STATS, c.TargetMode.SELF, 0, -1, -2, -1),
    effect(c, c.EffectType.GIVE_DIVINE_SHIELD, c.TargetMode.SELF),
    effect(c, c.EffectType.GIVE_TAUNT, c.TargetMode.SELF),
    effect(c, c.EffectType.GIVE_WINDFURY, c.TargetMode.SELF)
  ]);
  const result = run(c, [fixture(c, 5, 5, [aura])], []);
  let slots = c.replaySlots(result.playerInit);
  for (const e of result.events) slots = c.reduceReplay(slots, c.Side.PLAYER, { ...e, text: '?' });
  const m = slots[0].minion;
  assert.equal(m.atk, 3); assert.equal(m.hp, 4); assert.equal(m.maxHp, 5);
  for (const k of [c.Keyword.DIVINE_SHIELD, c.Keyword.TAUNT, c.Keyword.WINDFURY]) assert.ok(m.hasKeyword(k));
  assert.equal(result.events.filter(e => e.type === c.CombatEventType.STAT_CHANGE).length, 4);
});
test('engine does not overwrite simulator snapshot IDs', async () => {
  const c = await ready;
  const engine = new c.GameEngine(c.ALL_HEROES[0], new c.Rng(1));
  engine.player.board = [named(c, '鱼人领袖')];
  engine.onBattleResolved(result => {
    const change = result.events.find(e => e.type === c.CombatEventType.STAT_CHANGE);
    assert.equal(change.actorUid, result.playerInit[0].uid);
  });
  engine.endRecruitAndFight();
});
test('seeded library battles replay surviving totals with unique deaths', async () => {
  const c = await ready;
  for (let seed = 1; seed <= 50; seed++) {
    const rng = new c.Rng(seed);
    const board = () => Array.from({ length: 7 }, () => {
      const d = rng.pick(c.ALL_MINIONS);
      return new c.Minion(rng.next() < 0.5 ? c.goldenVersion(d) : d, c.nextUid());
    });
    const result = c.simulateBattle(board(), board(), rng);
    deathsOnce(c, result);
    let p = c.replaySlots(result.playerInit), a = c.replaySlots(result.aiInit);
    for (const e of result.events) {
      p = c.reduceReplay(p, c.Side.PLAYER, e); a = c.reduceReplay(a, c.Side.AI, e);
    }
    const total = slots => slots.reduce((sum, s) => sum + (s.minion.hp > 0 ? s.minion.atk : 0), 0);
    assert.equal(total(p), result.playerRemainingAtk, `player seed ${seed}`);
    assert.equal(total(a), result.aiRemainingAtk, `ai seed ${seed}`);
  }
});
