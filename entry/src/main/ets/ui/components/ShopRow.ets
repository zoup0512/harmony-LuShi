/**
 * 酒馆战棋 - 商店行组件
 *
 * 横向排列当前商店中可购买的随从，点击触发购买回调。
 * 商店下方是操作按钮（刷新/升级/冻结/技能）。
 */

import { Minion } from '../../game/model/Minion';
import { MINION_BY_ID } from '../../game/data/MinionLibrary';
import { GameConfig } from '../../game/GameConfig';
import { Theme } from '../Theme';
import { MinionCard } from './MinionCard';

@Component
export struct ShopRow {
  /** 商店随从列表 */
  @Link minions: Minion[];
  /** 当前金币 */
  @Prop gold: number = 0;
  /** 购买回调（参数：商店索引） */
  onBuy: (index: number) => void = () => {};
  /** 手牌是否已满（满则不可购买） */
  @Prop handFull: boolean = false;
  /** 商店是否冻结 */
  @Prop frozen: boolean = false;

  build() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        ForEach(this.minions, (m: Minion, idx: number) => {
          MinionCard({
            minion: m,
            cardWidth: 78, cardHeight: 106,
            showPrice: true,
            clickable: this.canAfford(m) && !this.handFull,
            dimmed: !this.canAfford(m) || this.handFull,
            onTap: (clicked: Minion) => this.onBuy(idx)
          })
        }, (m: Minion, idx: number) => idx.toString() + '_' + m.uid)
      }
      .width('100%')
      .height(112)
      .justifyContent(FlexAlign.Center)
      if (this.frozen) {
        Row({ space: 4 }) {
          Text('❄').fontSize(14).fontColor('#B8F0FF')
          Text('商店已冻结').fontSize(10).fontColor('#D8F8FF').fontWeight(FontWeight.Bold)
        }
        .backgroundColor('#991A5970').borderRadius(8).padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .position({ x: '50%', y: 0 }).translate({ x: '-50%' })
      }
    }
    .width('100%').padding({ top: this.frozen ? 18 : 0 })
  }

  private canAfford(m: Minion): boolean {
    const def = MINION_BY_ID.get(m.defId);
    if (!def) return false;
    return this.gold >= GameConfig.buyCost(def.tier);
  }
}
