import { PlayerState, HeroDef } from '../../game/model/Hero';
import { Theme } from '../Theme';
import { ArtAssets, ART_COIN, ART_HEALTH, ART_TAVERN } from '../ArtAssets';

function emptyHero(): HeroDef { return new HeroDef(); }

@Component
export struct HeroPanel {
  state: PlayerState = new PlayerState(emptyHero());
  @Prop isOpponent: boolean = false;
  @Prop showGold: boolean = true;

  build() {
    Row({ space: 8 }) {
      if (this.isOpponent) { this.infoBlock(); this.avatarBlock(); }
      else { this.avatarBlock(); this.infoBlock(); }
    }.padding({ left: 8, right: 8, top: 6, bottom: 6 })
  }

  @Builder
  avatarBlock() {
    Stack() {
      Image(ArtAssets.hero(this.state.hero.id)).width(44).height(44).objectFit(ImageFit.Cover).borderRadius(22)
      Column().width(44).height(44).borderRadius(22).backgroundColor('#33000000')
      if (this.isOpponent) {
        Text('敌').fontSize(9).fontColor('#FFFFFF').backgroundColor(Theme.HP_RED).borderRadius(6)
          .padding({ left: 4, right: 4 }).position({ x: 0, y: 0 })
      }
    }.width(48).height(48).borderRadius(24).backgroundColor(this.state.hero.color)
      .border({ width: 2, color: Theme.GOLD }).shadow({ radius: 8, color: '#D4A84B66', offsetX: 0, offsetY: 1 })
  }

  @Builder
  infoBlock() {
    Column({ space: 3 }) {
      Row() {
        Text(this.state.hero.name).fontSize(12).fontColor(Theme.TEXT_PRIMARY).fontWeight(FontWeight.Bold).layoutWeight(1)
        Row({ space: 2 }) {
          Image(ART_HEALTH).width(16).height(16)
          Text(`${Math.max(0, this.state.health)}`).fontSize(13).fontColor(Theme.hpColor(this.healthRatio())).fontWeight(FontWeight.Bold)
        }
      }.width('100%')
      Stack({ alignContent: Alignment.Start }) {
        Column().width('100%').height(7).backgroundColor('#66000000').borderRadius(4)
        Column().width(`${Math.min(1, this.healthRatio()) * 100}%`).height(7).backgroundColor(Theme.hpColor(this.healthRatio())).borderRadius(4)
      }.width('100%')
      Row({ space: 8 }) {
        if (this.showGold) {
          Row({ space: 2 }) {
            Image(ART_COIN).width(14).height(14)
            Text(`${this.state.gold}`).fontSize(11).fontColor(Theme.GOLD_COIN).fontWeight(FontWeight.Bold)
          }
        }
        Row({ space: 2 }) {
          Image(ART_TAVERN).width(14).height(14)
          Text(`酒馆 ${this.state.tavernTier}级`).fontSize(10).fontColor(Theme.TEXT_SECONDARY)
        }
        Text(this.state.hero.skill ? `技能:${this.state.hero.skill.name}` : '').fontSize(9).fontColor(Theme.TEXT_DIM)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }.width('100%')
    }.layoutWeight(1)
  }

  private healthRatio(): number { return Math.max(0, this.state.health) / this.state.hero.baseHealth; }
}
