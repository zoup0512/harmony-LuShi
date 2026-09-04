import { router } from '@kit.ArkUI';
import { Session } from '../ui/Session';
import { Theme } from '../ui/Theme';
import { ART_BACKGROUND_RESULT, ART_HEALTH, ART_TAVERN } from '../ui/ArtAssets';

@Entry
@Component
struct ResultPage {
  @State won: boolean = false;
  @State round: number = 0;

  aboutToAppear(): void { this.won = Session.lastWon; this.round = Session.lastRound; }

  build() {
    Stack() {
      Image(ART_BACKGROUND_RESULT).width('100%').height('100%').objectFit(ImageFit.Cover)
      Column().width('100%').height('100%').backgroundColor(this.won ? '#66130F25' : '#99110818')
      Column({ space: 16 }) {
        Image(this.won ? ART_TAVERN : ART_HEALTH).width(76).height(76).margin({ top: 50 })
        Text(this.won ? '荣 耀 胜 利' : '英 雄 倒 下').fontSize(38)
          .fontColor(this.won ? Theme.GOLD : Theme.HP_RED).fontWeight(FontWeight.Bold)
        Text(this.won ? '你击败了对手的英雄！' : '你的英雄倒下了…').fontSize(14).fontColor(Theme.TEXT_SECONDARY)
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Image(ART_TAVERN).width(20).height(20)
            Text('坚持回合').fontSize(13).fontColor(Theme.TEXT_SECONDARY)
            Text(`${this.round}`).fontSize(20).fontColor(Theme.GOLD).fontWeight(FontWeight.Bold)
          }
          Row({ space: 10 }) {
            Image(ART_HEALTH).width(20).height(20)
            Text('剩余血量').fontSize(13).fontColor(Theme.TEXT_SECONDARY)
            Text(`${Math.max(0, Session.get()?.player.health ?? 0)}`).fontSize(20)
              .fontColor(Theme.hpColor((Session.get()?.player.health ?? 0) / 40)).fontWeight(FontWeight.Bold)
          }
        }
        .width('72%').padding(20).margin({ top: 12 }).borderRadius(12).backgroundColor(Theme.BG_GLASS)
        .border({ width: 1.5, color: Theme.GOLD_DIM }).shadow({ radius: 10, color: '#00000088', offsetX: 0, offsetY: 3 })
        Button('再 来 一 局').type(ButtonType.Capsule).fontSize(16).fontColor('#3A2A0A').fontWeight(FontWeight.Bold)
          .width('60%').height(46).backgroundColor(Theme.GOLD).margin({ top: 22 })
          .onClick(() => { Session.clear(); router.replaceUrl({ url: 'pages/MainMenuPage' }); })
        Button('返 回 标 题').type(ButtonType.Capsule).fontSize(14).fontColor(Theme.TEXT_PRIMARY)
          .width('60%').height(42).backgroundColor(Theme.BG_GLASS_DARK).border({ width: 1.5, color: Theme.GOLD_DIM })
          .onClick(() => { Session.clear(); router.replaceUrl({ url: 'pages/MainMenuPage' }); })
      }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
    }.width('100%').height('100%')
  }
}

export default ResultPage;
