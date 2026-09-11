/**
 * 酒馆战棋 - 游戏主页
 *
 * 整合英雄面板、AI 阵容预览、玩家战场、手牌、商店与操作按钮。
 * 通过订阅 GameEngine 的状态变更回调驱动 UI 刷新。
 *
 * 交互逻辑：
 * - 点击商店随从 → 购买到手牌；
 * - 点击手牌随从 → 打到战场；
 * - 点击战场随从 → 选中（可卖出/换位）；
 * - 操作按钮：刷新 / 升级 / 冻结 / 技能 / 战斗。
 */

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { GameEngine } from '../game/engine/GameEngine';
import { Session } from '../ui/Session';
import { Theme } from '../ui/Theme';
import { HeroPanel } from '../ui/components/HeroPanel';
import { BoardRow } from '../ui/components/BoardRow';
import { HandRow } from '../ui/components/HandRow';
import { ShopRow } from '../ui/components/ShopRow';
import { ActionButton } from '../ui/components/ActionButton';
import { BattleReplay } from '../ui/components/BattleReplay';
import { Minion } from '../game/model/Minion';
import { GameConfig } from '../game/GameConfig';
import { BattleResult } from '../game/combat/CombatTypes';
import { ALL_HEROES } from '../game/data/HeroLibrary';
import { PlayerState } from '../game/model/Hero';
import { ART_BACKGROUND_GAME, ART_COIN } from '../ui/ArtAssets';

@Entry
@Component
struct GamePage {
  private engine: GameEngine | null = null;
  @State playerSnapshot: PlayerState = new PlayerState(ALL_HEROES[0]);
  @State aiSnapshot: PlayerState = new PlayerState(ALL_HEROES[0]);
  @State roundSnapshot: number = 1;
  @State frozenSnapshot: boolean = false;
  @State battleRound: number = 1;
  @State selectedBoardUid: number = -1;
  @State inBattle: boolean = false;
  @State currentBattle: BattleResult = new BattleResult();
  @State toast: string = '';

  aboutToAppear(): void {
    this.engine = Session.get();
    if (!this.engine) {
      // 没有会话，返回主菜单
      router.replaceUrl({ url: 'pages/MainMenuPage' });
      return;
    }
    this.refreshSnapshots();
    this.engine.onStateChange(() => {
      this.refreshSnapshots();
    });
    this.engine.onBattleResolved((result, playerDamage) => {
      this.battleRound = this.engine!.round;
      this.currentBattle = result;
      this.inBattle = true;
      if (playerDamage > 0) {
        this.showToast(`受到 ${playerDamage} 点伤害！`);
      } else if (result.outcome === 0) {
        this.showToast(`胜利！对敌方造成 ${result.aiDamageTaken} 伤害`);
      }
    });
    this.engine.onGameOver((won) => {
      Session.lastWon = won;
      Session.lastRound = this.engine!.round;
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/ResultPage' });
      }, 600);
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Image(ART_BACKGROUND_GAME).width('100%').height('100%').objectFit(ImageFit.Cover)
      Column().width('100%').height('100%').backgroundColor('#66040A14')
      Column() {
        // 顶部：双方英雄面板
        Row() {
          Column() {
            HeroPanel({
              state: this.aiState(), isOpponent: true, showGold: false
            })
          }
          .layoutWeight(1)

          Column({ space: 2 }) {
            Text(`第 ${this.round()} 回合`)
              .fontSize(11)
              .fontColor(Theme.GOLD)
            Row({ space: 3 }) {
              Image(ART_COIN).width(17).height(17)
              Text(this.playerGold().toString()).fontSize(14).fontColor(Theme.GOLD_COIN).fontWeight(FontWeight.Bold)
            }
          }
          .width(80)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: 6, right: 6, top: 4 })

        Divider().color(Theme.GOLD_DIM).strokeWidth(1)

        // 玩家英雄面板
        HeroPanel({
          state: this.playerState(), isOpponent: false, showGold: false
        })

        // 战场区（玩家）
        BoardRow({
          minions: this.playerBoard(),
          isPlayer: true,
          selectedUid: this.selectedBoardUid,
          title: '我的战场',
          onTap: (m: Minion, idx: number) => this.onBoardTap(m, idx)
        })

        // 选中随从的操作条
        if (this.selectedBoardUid >= 0) {
          Row({ space: 8 }) {
            Text('已选中')
              .fontSize(11)
              .fontColor(Theme.TEXT_PRIMARY)
            Button('卖出 +1🪙')
              .fontSize(11)
              .height(30)
              .backgroundColor(Theme.GOLD_DIM)
              .onClick(() => this.sellSelected())
            Button('取消')
              .fontSize(11)
              .height(30)
              .backgroundColor('#444444')
              .onClick(() => { this.selectedBoardUid = -1; })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 2, bottom: 2 })
        }

        // 手牌区
        HandRow({
          minions: this.playerHand(),
          boardFull: this.playerBoard().length >= GameConfig.BOARD_SIZE,
          onPlay: (idx: number) => this.playHand(idx)
        })

        Divider().color(Theme.GOLD_DIM).strokeWidth(1)

        // 商店区
        ShopRow({
          minions: this.playerShop(),
          gold: this.playerGold(),
          handFull: this.playerHand().length >= 10,
          frozen: this.frozenSnapshot,
          onBuy: (idx: number) => this.buy(idx)
        })

        // 操作按钮行
        Row({ space: 8 }) {
          ActionButton({
            label: '刷新', sub: '1 金币', icon: 'refresh',
            isEnabled: this.canRefresh(),
            btnColor: '#3A6B8E',
            onTap: () => { this.engine!.refreshShop(); }
          })
          ActionButton({
            label: '升级', sub: `${this.upgradeCost()} 金币`, icon: 'upgrade',
            isEnabled: this.canUpgrade(),
            btnColor: '#6B4E8E',
            onTap: () => { this.engine!.upgradeTavern(); }
          })
          ActionButton({
            label: this.frozenSnapshot ? '已冻结' : '冻结', sub: '保留下回合', icon: 'freeze',
            isEnabled: true,
            btnColor: this.frozenSnapshot ? '#2A4A6A' : '#4A6A2A',
            onTap: () => { this.engine!.toggleFreeze(); }
          })
          ActionButton({
            label: '技能', sub: this.skillSubText(), icon: 'skill',
            isEnabled: this.canUseSkill(),
            btnColor: '#8E4E3A',
            onTap: () => { this.engine!.useHeroSkill(); }
          })
          ActionButton({
            label: '战斗', sub: '开打!', icon: 'battle',
            isEnabled: !this.inBattle,
            btnColor: '#A03030',
            onTap: () => { this.startBattle(); }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: 4, bottom: 6 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#4D0E1A2B')

      // 战斗回放层（覆盖全屏）
      if (this.inBattle) {
        Column() {
          BattleReplay({
            result: this.currentBattle,
            round: this.battleRound,
            onFinish: () => {
              this.inBattle = false;
            }
          })
        }
        .width('100%')
        .height('100%')
      }

      // Toast 提示
      if (this.toast.length > 0) {
        Text(this.toast)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#000000CC')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .position({ x: '50%', y: '15%' })
          .translate({ x: '-50%' })
      }
    }
    .width('100%')
    .height('100%')
  }

  // 引擎模型不是 @Observed；每次通知发布新的、隔离的 @State 快照。
  private snapshot(source: PlayerState): PlayerState {
    const copy = new PlayerState(source.hero);
    copy.health = source.health;
    copy.gold = source.gold;
    copy.tavernTier = source.tavernTier;
    copy.upgradeCost = source.upgradeCost;
    copy.refreshCost = source.refreshCost;
    copy.skillUsed = source.skillUsed;
    copy.board = source.board.map((m) => m.clone(m.uid));
    copy.hand = source.hand.map((m) => m.clone(m.uid));
    copy.shop = source.shop.map((m) => m.clone(m.uid));
    return copy;
  }

  private refreshSnapshots(): void {
    if (!this.engine) return;
    this.playerSnapshot = this.snapshot(this.engine.player);
    this.aiSnapshot = this.snapshot(this.engine.ai);
    this.roundSnapshot = this.engine.round;
    this.frozenSnapshot = this.engine.frozen;
  }

  private round(): number { return this.roundSnapshot; }
  private playerGold(): number { return this.playerSnapshot.gold; }
  private upgradeCost(): number { return this.playerSnapshot.upgradeCost; }
  private playerState(): PlayerState { return this.playerSnapshot; }
  private aiState(): PlayerState { return this.aiSnapshot; }
  private playerBoard(): Minion[] { return this.playerSnapshot.board; }
  private playerHand(): Minion[] { return this.playerSnapshot.hand; }
  private playerShop(): Minion[] { return this.playerSnapshot.shop; }

  // ---------------- 交互处理 ----------------

  private buy(idx: number): void {
    if (this.engine!.buyMinion(idx)) {
      this.showToast('已购买');
    } else {
      this.showToast('金币不足或手牌已满');
    }
  }

  private playHand(idx: number): void {
    if (this.playerBoard().length >= GameConfig.BOARD_SIZE) {
      this.showToast('战场已满');
      return;
    }
    this.engine!.playFromHand(idx);
  }

  private onBoardTap(m: Minion, idx: number): void {
    if (this.selectedBoardUid === m.uid) {
      this.selectedBoardUid = -1;
    } else {
      this.selectedBoardUid = m.uid;
    }
  }

  private sellSelected(): void {
    if (this.selectedBoardUid < 0) return;
    const idx = this.playerBoard().findIndex((m) => m.uid === this.selectedBoardUid);
    if (idx >= 0) {
      this.engine!.sellMinion(true, idx);
      this.selectedBoardUid = -1;
      this.showToast('已卖出');
    }
  }

  private startBattle(): void {
    if (this.playerBoard().length === 0) {
      this.showToast('战场上至少要有一个随从');
      return;
    }
    this.engine!.endRecruitAndFight();
  }

  // ---------------- 工具 ----------------

  private canRefresh(): boolean {
    return !!this.engine && this.playerSnapshot.gold >= GameConfig.REFRESH_COST && !this.inBattle;
  }
  private canUpgrade(): boolean {
    return !!this.engine && this.playerSnapshot.tavernTier < 6 &&
      this.playerSnapshot.gold >= this.playerSnapshot.upgradeCost && !this.inBattle;
  }
  private canUseSkill(): boolean {
    return !!this.engine && !this.playerSnapshot.skillUsed &&
      this.playerSnapshot.gold >= (this.playerSnapshot.hero.skill?.cost ?? 99) && !this.inBattle;
  }
  private skillSubText(): string {
    const skill = this.playerSnapshot.hero.skill;
    if (!skill) return '';
    return this.playerSnapshot.skillUsed ? '已用' : `${skill.cost}🪙`;
  }

  private showToast(msg: string): void {
    this.toast = msg;
    setTimeout(() => {
      if (this.toast === msg) this.toast = '';
    }, 1600);
  }

  private emptyPlayer(): PlayerState {
    // 占位，避免 null 导致渲染崩溃
    return new PlayerState(ALL_HEROES[0]);
  }
}

export default GamePage;
