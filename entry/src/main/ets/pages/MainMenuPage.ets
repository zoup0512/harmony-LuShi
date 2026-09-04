import { router } from '@kit.ArkUI';
import { ALL_HEROES } from '../game/data/HeroLibrary';
import { HeroDef } from '../game/model/Hero';
import { Theme } from '../ui/Theme';
import { Session } from '../ui/Session';
import { ArtAssets, ART_BACKGROUND_MENU, ART_TAVERN } from '../ui/ArtAssets';

@Entry
@Component
struct MainMenuPage {
  @State selectedHeroIdx: number = 0;
  @State heroes: HeroDef[] = ALL_HEROES;

  private cloneHero(src: HeroDef): HeroDef {
    const h = new HeroDef(); h.id = src.id; h.name = src.name; h.icon = src.icon;
    h.color = src.color; h.baseHealth = src.baseHealth; h.skill = src.skill; return h;
  }

  build() {
    Stack() {
      Image(ART_BACKGROUND_MENU).width('100%').height('100%').objectFit(ImageFit.Cover)
      Column().width('100%').height('100%').backgroundColor(Theme.SCRIM)
      Column() {
        Column({ space: 5 }) {
          Image(ART_TAVERN).width(54).height(54).margin({ top: 22 })
          Text('秘境酒馆').fontSize(34).fontColor(Theme.GOLD).fontWeight(FontWeight.Bold).letterSpacing(4)
          Text('原创暗色奇幻 · 自走棋对局').fontSize(12).fontColor(Theme.TEXT_SECONDARY)
        }.width('100%')
        Text('选择你的英雄').fontSize(18).fontColor(Theme.TEXT_PRIMARY).fontWeight(FontWeight.Bold).margin({ top: 15, bottom: 8 })
        Scroll() {
          Row({ space: 10 }) {
            ForEach(this.heroes, (h: HeroDef, idx: number) => {
              Column({ space: 4 }) {
                Image(ArtAssets.hero(h.id)).width(54).height(54).borderRadius(27).objectFit(ImageFit.Cover)
                Text(h.name).fontSize(10).fontColor(Theme.TEXT_PRIMARY).fontWeight(FontWeight.Bold).maxLines(1)
              }
              .width(80).height(96).borderRadius(12).backgroundColor('#C9233652')
              .border({ width: this.selectedHeroIdx === idx ? 3 : 1.5, color: this.selectedHeroIdx === idx ? Theme.GOLD : h.color })
              .shadow({ radius: this.selectedHeroIdx === idx ? 12 : 4, color: this.selectedHeroIdx === idx ? '#D4A84B99' : '#00000066', offsetX: 0, offsetY: 2 })
              .justifyContent(FlexAlign.Center).onClick(() => { this.selectedHeroIdx = idx; })
            }, (h: HeroDef, idx: number) => idx.toString())
          }.padding({ left: 12, right: 12 })
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').height(110)
        this.heroDetail()
        Button('进入酒馆').type(ButtonType.Capsule).fontSize(18).fontColor('#3A2A0A').fontWeight(FontWeight.Bold)
          .width('70%').height(48).backgroundColor(Theme.GOLD).margin({ top: 16, bottom: 12 })
          .shadow({ radius: 12, color: '#D4A84B77', offsetX: 0, offsetY: 3 })
          .onClick(() => { Session.start(this.cloneHero(this.heroes[this.selectedHeroIdx])); router.replaceUrl({ url: 'pages/GamePage' }); })
        Column({ space: 4 }) {
          Text('◆ 购买随从，构筑你的战场').fontSize(10).fontColor(Theme.TEXT_SECONDARY)
          Text('◆ 三张同名随从可合成金色').fontSize(10).fontColor(Theme.TEXT_SECONDARY)
          Text('◆ 准备完成后自动展开战斗').fontSize(10).fontColor(Theme.TEXT_SECONDARY)
        }.alignItems(HorizontalAlign.Start).padding(10).backgroundColor(Theme.BG_GLASS_DARK).borderRadius(8)
      }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
    }.width('100%').height('100%')
  }

  @Builder
  heroDetail() {
    Row({ space: 12 }) {
      Image(ArtAssets.hero(this.heroes[this.selectedHeroIdx].id)).width(70).height(70).borderRadius(35).objectFit(ImageFit.Cover)
        .border({ width: 2, color: Theme.GOLD })
      Column({ space: 4 }) {
        Text(this.heroes[this.selectedHeroIdx].name).fontSize(16).fontColor(Theme.TEXT_PRIMARY).fontWeight(FontWeight.Bold)
        Text(`初始血量 ${this.heroes[this.selectedHeroIdx].baseHealth}`).fontSize(10).fontColor(Theme.TEXT_SECONDARY)
        if (this.heroes[this.selectedHeroIdx].skill) {
          Text(`✦ ${this.heroes[this.selectedHeroIdx].skill!.name} · ${this.heroes[this.selectedHeroIdx].skill!.cost} 金币`)
            .fontSize(11).fontColor(Theme.GOLD).fontWeight(FontWeight.Bold)
          Text(this.heroes[this.selectedHeroIdx].skill!.desc).fontSize(10).fontColor(Theme.TEXT_SECONDARY).maxLines(2)
        }
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('88%').padding(12).margin({ top: 7 }).borderRadius(12).backgroundColor(Theme.BG_GLASS)
    .border({ width: 1.5, color: Theme.GOLD_DIM }).shadow({ radius: 10, color: '#00000088', offsetX: 0, offsetY: 3 })
  }
}

export default MainMenuPage;
