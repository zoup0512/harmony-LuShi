import { Minion } from '../model/Minion';
import { Keyword, Side } from '../model/Types';
import { CombatEvent, CombatEventType } from './CombatTypes';

export interface BoardSlot {
  minion: Minion | null;
  flashing: boolean;
  floatText: string;
}

export function replaySlots(minions: Minion[]): BoardSlot[] {
  return minions.map((m): BoardSlot => {
    return { minion: m.clone(m.uid), flashing: false, floatText: '' };
  });
}

/** Pure single-side reducer: text is presentation only; each frame owns its state. */
export function reduceReplay(slots: BoardSlot[], side: Side, event: CombatEvent): BoardSlot[] {
  let next = slots.map((slot): BoardSlot => {
    return {
      minion: slot.minion ? slot.minion.clone(slot.minion.uid) : null,
      flashing: false, floatText: ''
    };
  });
  const actorEvent = event.type === CombatEventType.DEATH ||
    event.type === CombatEventType.REBORN_TRIGGER || event.type === CombatEventType.SHIELD_BLOCK;
  const eventSide = actorEvent ? event.actorSide : event.targetSide;
  if (side !== eventSide) return next;
  const uid = actorEvent ? event.actorUid : event.targetUid;
  if (event.type === CombatEventType.SUMMON) {
    if (event.minionState && !next.some((s) => s.minion?.uid === uid)) {
      // Simulator appends summons after survivors, rather than filling old positions.
      next = next.filter((s) => s.minion !== null);
      // Capacity is decided by the simulator using living minions. A pending
      // death may still be visible until the next batch emits its DEATH event.
      next.push({ minion: event.minionState.clone(uid), flashing: true, floatText: '召唤' });
    }
    return next;
  }
  const slot = next.find((s) => s.minion?.uid === uid);
  if (!slot || !slot.minion) return next;
  switch (event.type) {
    case CombatEventType.DEATH:
      next = next.filter((s) => s !== slot);
      break;
    case CombatEventType.SHIELD_BLOCK:
      slot.minion.removeKeyword(Keyword.DIVINE_SHIELD);
      slot.flashing = true;
      slot.floatText = '圣盾!';
      break;
    case CombatEventType.DAMAGE:
    case CombatEventType.STAT_CHANGE:
    case CombatEventType.REBORN_TRIGGER:
      if (event.minionState) slot.minion = event.minionState.clone(uid);
      slot.flashing = true;
      slot.floatText = event.type === CombatEventType.DAMAGE ? `-${event.amount}` : event.text;
      break;
    default:
      break;
  }
  return next;
}
