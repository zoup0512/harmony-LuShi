/**
 * 酒馆战棋 - 战斗回放组件
 *
 * 把 BattleSimulator 产出的事件序列逐帧回放，让玩家看到自动战斗的过程。
 *
 * 实现思路：维护一个"当前回合快照"（双方随从的实时状态），用一个定时器
 * 每隔 ~600ms 推进一个事件，根据事件类型更新快照（伤害、死亡、召唤等），
 * 并把变化渲染到屏幕上。事件全部播放完后展示结果。
 */

import { Side } from '../../game/model/Types';
import {
  BattleResult, CombatEvent, CombatEventType, BattleOutcome
} from '../../game/combat/CombatTypes';
import { Theme } from '../Theme';
import { MinionCard } from './MinionCard';
import { BoardSlot, replaySlots, reduceReplay } from '../../game/combat/ReplayReducer';
import { ART_BACKGROUND_BATTLE } from '../ArtAssets';

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
    this.playerSlots = replaySlots(this.result.playerInit);
    this.aiSlots = replaySlots(this.result.aiInit);
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
    this.playerSlots = reduceReplay(this.playerSlots, Side.PLAYER, e);
    this.aiSlots = reduceReplay(this.aiSlots, Side.AI, e);
    this.statusText = e.type === CombatEventType.START ? `第 ${this.round} 回合 · 战斗开始` : e.text;
    this.highlightUid = e.type === CombatEventType.ATTACK ? e.actorUid : -1;
    if (e.type === CombatEventType.END) this.finished = true;
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
