/**
 * 酒馆战棋 - 战斗回放组件
 *
 * 把 BattleSimulator 产出的事件序列逐帧回放，让玩家看到自动战斗的过程。
 *
 * 实现思路：维护一个"当前回合快照"（双方随从的实时状态），用一个定时器
 * 每隔 ~600ms 推进一个事件，根据事件类型更新快照（伤害、死亡、召唤等），
 * 并把变化渲染到屏幕上。事件全部播放完后展示结果。
 */

import { Minion, MinionDef } from '../../game/model/Minion';
import { Keyword, Side } from '../../game/model/Types';
import { MINION_BY_ID } from '../../game/data/MinionLibrary';
import {
  BattleResult, CombatEvent, CombatEventType, BattleOutcome
} from '../../game/combat/CombatTypes';
import { Theme } from '../Theme';
import { MinionCard } from './MinionCard';
import { nextUid } from '../../game/util/Rng';
import { ART_BACKGROUND_BATTLE } from '../ArtAssets';

interface BoardSlot {
  minion: Minion | null;
  /** 本帧是否刚受击（飘字高亮） */
  flashing: boolean;
  /** 本帧飘字内容 */
  floatText: string;
}

@Component
export struct BattleReplay {
  /** 战斗结果（事件源） */
  result: BattleResult = new BattleResult();
  /** 回合数（仅用于标题展示） */
  @Prop round: number = 1;
  /** 回放结束回调 */
  onFinish: () => void = () => {};

  @State playerSlots: BoardSlot[] = [];
  @State aiSlots: BoardSlot[] = [];
  @State eventIdx: number = 0;
  @State statusText: string = '战斗开始';
  @State finished: boolean = false;
  @State highlightUid: number = -1;
  private timerId: number = -1;

  aboutToAppear(): void {
    // 用结果中的初始随从初始化槽位
    this.initSlots();
    // 启动定时推进
    this.scheduleNext();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
    }
  }

  private initSlots(): void {
    // 从 START 之后的事件无法直接得到初始阵容，因此用一个临时映射重建。
    // 我们扫描所有事件，收集出现过的 uid 到阵营；但更可靠的是在引擎里把初始阵容也存进结果。
    // 这里采用：BattleResult 的事件中第一个 ATTACK 之前不会改变阵容，所以我们用"所有出现过的 uid"作为初始。
    // 为简化，我们改为在 GameEngine 调用时把初始阵容也放进 result（见 CombatTypes 扩展）。
    // 此处用 result.playerInit / aiInit（在引擎里赋值）。
    this.playerSlots = this.toSlots(this.result.playerInit);
    this.aiSlots = this.toSlots(this.result.aiInit);
  }

  private toSlots(minions: Minion[]): BoardSlot[] {
    const result: BoardSlot[] = [];
    for (const m of minions) {
      const slot: BoardSlot = {
        minion: m.clone(m.uid), flashing: false, floatText: ''
      };
      result.push(slot);
    }
    return result;
  }

  private scheduleNext(): void {
    this.timerId = setTimeout(() => {
      this.advance();
    }, 650);
  }

  private advance(): void {
    if (this.eventIdx >= this.result.events.length) {
      this.finished = true;
      // 短暂停留后通知上层
      this.timerId = setTimeout(() => {
        this.onFinish();
      }, 1200);
      return;
    }
    const e = this.result.events[this.eventIdx];
    this.eventIdx++;
    this.applyEvent(e);
    this.scheduleNext();
  }

  private applyEvent(e: CombatEvent): void {
    // 清除上一帧的高亮
    for (const s of this.playerSlots) { s.flashing = false; s.floatText = ''; }
    for (const s of this.aiSlots) { s.flashing = false; s.floatText = ''; }

    switch (e.type) {
      case CombatEventType.START:
        this.statusText = `第 ${this.round} 回合 · 战斗开始`;
        this.highlightUid = -1;
        break;
      case CombatEventType.ATTACK: {
        this.statusText = '攻击！';
        this.highlightUid = e.actorUid;
        break;
      }
      case CombatEventType.DAMAGE: {
        const slots = e.targetSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const slot = this.findSlot(slots, e.targetUid);
        if (slot && slot.minion) {
          slot.minion.hp -= e.amount;
          if (slot.minion.hp < 0) slot.minion.hp = 0;
          slot.flashing = true;
          slot.floatText = `-${e.amount}`;
        }
        this.statusText = `造成 ${e.amount} 伤害`;
        break;
      }
      case CombatEventType.SHIELD_BLOCK: {
        const slots = e.actorSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const slot = this.findSlot(slots, e.actorUid);
        if (slot && slot.minion) {
          slot.minion.removeKeyword(Keyword.DIVINE_SHIELD);
          slot.flashing = true;
          slot.floatText = '圣盾!';
        }
        this.statusText = '圣盾抵消';
        break;
      }
      case CombatEventType.DEATH: {
        const slots = e.actorSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const slot = this.findSlot(slots, e.actorUid);
        if (slot) {
          slot.minion = null;
        }
        this.statusText = '随从阵亡';
        break;
      }
      case CombatEventType.DEATHRATTLE:
        this.statusText = '亡语触发';
        break;
      case CombatEventType.SUMMON: {
        // 召唤一个新随从到对应方（用 text 里的名称创建一个占位）
        const slots = e.actorSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const empty = slots.findIndex((s) => s.minion === null);
        // 若没有空位则追加（最多 7）
        const def = this.guessDefFromText(e.text);
        if (def && slots.length < 7) {
          const m = new Minion(def, nextUid());
          if (empty >= 0) {
            slots[empty].minion = m;
          } else {
            const newSlot: BoardSlot = { minion: m, flashing: true, floatText: '召唤' };
            slots.push(newSlot);
          }
        }
        this.statusText = e.text;
        break;
      }
      case CombatEventType.STAT_CHANGE: {
        const slots = e.targetSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const slot = this.findSlot(slots, e.targetUid);
        if (slot && slot.minion) {
          // 解析 text 中的 +atk/+hp
          const match = e.text.match(/\+(\d+)\/\+(\d+)/);
          if (match) {
            slot.minion.atk += parseInt(match[1]);
            slot.minion.hp += parseInt(match[2]);
            slot.minion.maxHp += parseInt(match[2]);
          }
          slot.flashing = true;
          slot.floatText = e.text;
        }
        this.statusText = e.text;
        break;
      }
      case CombatEventType.REBORN_TRIGGER: {
        const slots = e.actorSide === Side.PLAYER ? this.playerSlots : this.aiSlots;
        const slot = this.findSlot(slots, e.actorUid);
        if (slot) {
          const def = slot.minion ? MINION_BY_ID.get(slot.minion.defId) : null;
          if (def) {
            const m = new Minion(def, nextUid());
            m.hp = 1;
            m.maxHp = 1;
            m.removeKeyword(Keyword.REBORN);
            slot.minion = m;
            slot.flashing = true;
            slot.floatText = '复生!';
          }
        }
        this.statusText = '复生';
        break;
      }
      case CombatEventType.END:
        this.finished = true;
        this.statusText = e.text;
        break;
      default:
        break;
    }
  }

  private findSlot(slots: BoardSlot[], uid: number): BoardSlot | null {
    for (const s of slots) {
      if (s.minion && s.minion.uid === uid) return s;
    }
    return null;
  }

  /** 从"召唤 招潮者"这样的文本里反推 def */
  private guessDefFromText(text: string): MinionDef | null {
    const parts = text.split(' ');
    if (parts.length < 2) return null;
    const name = parts.slice(1).join(' ');
    for (const def of MINION_BY_ID.values()) {
      if (def.name === name) return def;
    }
    return null;
  }

  build() {
    Stack() {
      Image(ART_BACKGROUND_BATTLE).width('100%').height('100%').objectFit(ImageFit.Cover)
      Column().width('100%').height('100%').backgroundColor('#B3050914')
      Column() {
      // 状态文本
      Text(this.statusText)
        .fontSize(16)
        .fontColor(Theme.GOLD)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 8, bottom: 8 })

      // AI 阵营（上方）
      Row({ space: 4 }) {
        ForEach(this.aiSlots, (slot: BoardSlot, idx: number) => {
          this.slotView(slot, true)
        }, (slot: BoardSlot, idx: number) => idx.toString())
      }
      .width('100%')
      .height(140)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 4, right: 4 })

      // VS 分隔
      Row() {
        Column().width(40).height(1).backgroundColor(Theme.GOLD_DIM)
        Text('VS')
          .fontSize(14)
          .fontColor(Theme.GOLD)
          .margin({ left: 8, right: 8 })
        Column().width(40).height(1).backgroundColor(Theme.GOLD_DIM)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4, bottom: 4 })

      // 玩家阵营（下方）
      Row({ space: 4 }) {
        ForEach(this.playerSlots, (slot: BoardSlot, idx: number) => {
          this.slotView(slot, false)
        }, (slot: BoardSlot, idx: number) => idx.toString())
      }
      .width('100%')
      .height(140)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 4, right: 4 })

      // 结束时显示结果
      if (this.finished) {
        Text(this.outcomeText())
          .fontSize(20)
          .fontColor(this.outcomeColor())
          .fontWeight(FontWeight.Bold)
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    }
    .width('100%').height('100%')
  }

  @Builder
  slotView(slot: BoardSlot, isAi: boolean) {
    Stack({ alignContent: Alignment.Top }) {
      if (slot.minion) {
        MinionCard({
          minion: slot.minion!,
          cardWidth: 78, cardHeight: 106,
          clickable: false,
          selected: slot.minion!.uid === this.highlightUid
        })
      } else {
        // 空槽位占位
        Column()
          .width(78)
          .height(106)
          .borderRadius(Theme.RADIUS_CARD)
          .backgroundColor('#1A1A1A')
          .border({ width: 1, color: '#333333', style: BorderStyle.Dashed })
      }
      // 受击飘字
      if (slot.flashing && slot.floatText.length > 0) {
        Text(slot.floatText)
          .fontSize(13)
          .fontColor('#FFD700')
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#000000AA')
          .borderRadius(6)
          .padding({ left: 4, right: 4 })
          .position({ x: 10, y: -6 })
      }
    }
    .width(78)
    .height(110)
  }

  private outcomeText(): string {
    switch (this.result.outcome) {
      case BattleOutcome.PLAYER_WIN: return '✦ 胜利 · 战场属于你';
      case BattleOutcome.AI_WIN: return '◆ 失败 · 重整旗鼓';
      default: return '◇ 平局 · 暂且休战';
    }
  }

  private outcomeColor(): string {
    switch (this.result.outcome) {
      case BattleOutcome.PLAYER_WIN: return Theme.HP_GREEN;
      case BattleOutcome.AI_WIN: return Theme.HP_RED;
      default: return Theme.TEXT_SECONDARY;
    }
  }
}
