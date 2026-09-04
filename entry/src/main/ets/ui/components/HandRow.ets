/**
 * 酒馆战棋 - 手牌行组件
 *
 * 横向排列手牌（购买后暂存的随从）。点击手牌中的随从将其打到战场上。
 * 手牌是横向滚动列表，避免在窄屏上溢出。
 */

import { Minion } from '../../game/model/Minion';
import { GameConfig } from '../../game/GameConfig';
import { Theme } from '../Theme';
import { MinionCard } from './MinionCard';

@Component
export struct HandRow {
  /** 手牌 */
  @Link minions: Minion[];
  /** 战场是否已满 */
  @Prop boardFull: boolean = false;
  /** 当前选中手牌 uid */
  @Prop selectedUid: number = -1;
  /** 打出回调 */
  onPlay: (index: number) => void = () => {};

  build() {
    Scroll() {
      Row({ space: 6 }) {
        ForEach(this.minions, (m: Minion, idx: number) => {
          MinionCard({
            minion: m,
            cardWidth: 74, cardHeight: 102,
            clickable: !this.boardFull,
            dimmed: this.boardFull,
            selected: m.uid === this.selectedUid,
            onTap: (clicked: Minion) => this.onPlay(idx)
          })
        }, (m: Minion, idx: number) => idx.toString() + '_' + m.uid)
      }
      .padding({ left: 6, right: 6 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(108)
    .backgroundColor('#C90D1626')
    .borderRadius(8)
    .border({ width: 1, color: Theme.GOLD_DIM })
    .shadow({ radius: 5, color: '#00000066', offsetX: 0, offsetY: 2 })
  }
}
