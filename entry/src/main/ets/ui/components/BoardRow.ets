/**
 * 酒馆战棋 - 战场行组件
 *
 * 横向排列一方战场上的随从（最多 7）。点击随从可触发选中（用于卖出/查看）。
 * 通过 isPlayer 控制是否可交互。
 */

import { Minion } from '../../game/model/Minion';
import { GameConfig } from '../../game/GameConfig';
import { Theme } from '../Theme';
import { MinionCard } from './MinionCard';

@Component
export struct BoardRow {
  /** 战场随从 */
  @Prop minions: Minion[] = [];
  /** 是否为玩家方（可交互） */
  @Prop isPlayer: boolean = true;
  /** 当前选中的随从 uid */
  @Prop selectedUid: number = -1;
  /** 点击回调 */
  onTap: (m: Minion, index: number) => void = () => {};
  /** 标题 */
  @Prop title: string = '';

  build() {
    Column({ space: 2 }) {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(10)
          .fontColor(Theme.TEXT_DIM)
          .alignSelf(ItemAlign.Start)
          .padding({ left: 4 })
      }
      Row({ space: 5 }) {
        ForEach(this.minions, (m: Minion, idx: number) => {
          MinionCard({
            minion: m,
            cardWidth: 72, cardHeight: 100,
            clickable: this.isPlayer,
            selected: this.isPlayer && m.uid === this.selectedUid,
            onTap: (clicked: Minion) => this.onTap(clicked, idx)
          })
        }, (m: Minion, idx: number) => idx.toString() + '_' + m.uid)
        // 空槽位占位（让玩家直观看到还能上几个）
        ForEach(this.emptySlots(), (idx: number) => {
          Column()
            .width(72)
            .height(100)
            .borderRadius(Theme.RADIUS_CARD)
            .backgroundColor('#152238')
            .border({ width: 1, color: '#2A3A55', style: BorderStyle.Dashed })
        }, (idx: number) => 'empty_' + idx.toString())
      }
      .width('100%')
      .height(104)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding({ top: 3, bottom: 3 })
    .backgroundColor('#A60D1828')
    .borderRadius(10)
    .border({ width: 1, color: '#665E7895' })
  }

  private emptySlots(): number[] {
    const arr: number[] = [];
    const need = GameConfig.BOARD_SIZE - this.minions.length;
    for (let i = 0; i < need; i++) arr.push(i);
    return arr;
  }
}
