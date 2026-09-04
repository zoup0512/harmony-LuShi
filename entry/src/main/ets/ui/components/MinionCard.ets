import { Minion, MinionDef } from '../../game/model/Minion';
import { Keyword, keywordShort, tribeName } from '../../game/model/Types';
import { MINION_BY_ID } from '../../game/data/MinionLibrary';
import { Theme } from '../Theme';
import { ArtAssets, ART_ATTACK, ART_HEALTH, ART_COIN } from '../ArtAssets';

@Component
export struct MinionCard {
  minion: Minion = new Minion(MINION_BY_ID.get(1000)!, 0);
  @Prop cardWidth: number = 92;
  @Prop cardHeight: number = 124;
  @Prop selected: boolean = false;
  @Prop clickable: boolean = true;
  @Prop showPrice: boolean = false;
  @Prop dimmed: boolean = false;
  onTap: (m: Minion) => void = () => {};

  private def(): MinionDef {
    return MINION_BY_ID.get(this.minion.defId) || new MinionDef();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.artBlock()
        Row({ space: 3 }) {
          ForEach(this.getKeywordList(), (k: Keyword) => {
            Stack() {
              Image(ArtAssets.keyword(k)).width(18).height(18).objectFit(ImageFit.Contain)
              Text(keywordShort(k)).fontSize(8).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
            }
            .width(20).height(18)
          })
        }.height(18).margin({ top: 2 })
        Column({ space: 1 }) {
          Text(this.def().name).fontSize(11).fontColor(Theme.TEXT_PRIMARY).fontWeight(FontWeight.Bold)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).textAlign(TextAlign.Center)
          Text(tribeName(this.def().tribe)).fontSize(8).fontColor(Theme.TEXT_SECONDARY)
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center).padding({ left: 4, right: 4 })
        Row() {
          Stack() {
            Image(ART_ATTACK).width(25).height(25)
            Text(this.minion.atk.toString()).fontSize(12).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
          }.width(26).height(26)
          Blank()
          Stack() {
            Image(ART_HEALTH).width(25).height(25)
            Text(this.minion.hp.toString()).fontSize(12).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
          }.width(26).height(26)
        }
        .width('100%').padding({ left: 4, right: 4, bottom: 3 })
      }
      .width(this.cardWidth).height(this.cardHeight).borderRadius(Theme.RADIUS_CARD)
      .backgroundColor(this.def().golden ? '#5A4419' : Theme.tribeColor(this.def().tribe))
      .border({ width: this.selected ? 3 : 1.5, color: this.selected ? Theme.GOLD : (this.def().golden ? Theme.GOLD : Theme.GOLD_DIM) })
      .opacity(this.dimmed ? 0.45 : 1.0)
      .shadow({ radius: this.selected ? 14 : 6, color: this.selected ? '#D4A84B88' : '#00000088', offsetX: 0, offsetY: 3 })
      .onClick(() => { if (this.clickable) this.onTap(this.minion); })
      if (this.def().golden) {
        Text('★').fontSize(14).fontColor(Theme.GOLD).position({ x: this.cardWidth - 18, y: 2 })
      }
      if (this.showPrice) {
        Row({ space: 2 }) {
          Image(ART_COIN).width(13).height(13)
          Text(this.priceText()).fontSize(10).fontColor(Theme.GOLD_COIN).fontWeight(FontWeight.Bold)
        }
        .backgroundColor('#D9000000').borderRadius(8).padding({ left: 4, right: 4, top: 1, bottom: 1 })
        .position({ x: 2, y: this.cardHeight - 17 })
      }
    }.width(this.cardWidth).height(this.cardHeight)
  }

  @Builder
  private artBlock() {
    Stack() {
      Image(ArtAssets.tribe(this.def().tribe)).width(this.cardWidth - 8).height(42).objectFit(ImageFit.Cover)
        .opacity(0.92).borderRadius(7)
      Column().width(this.cardWidth - 8).height(42).backgroundColor('#66040A14').borderRadius(7)
      Text(this.def().golden ? 'GOLDEN' : `TIER ${this.def().tier}`).fontSize(8).fontColor(Theme.TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold).letterSpacing(1).position({ x: 7, y: 4 })
    }.width(this.cardWidth - 8).height(42).margin({ left: 4, right: 4, top: 4 })
  }

  private getKeywordList(): Keyword[] {
    const arr: Keyword[] = [];
    if (this.minion.hasKeyword(Keyword.TAUNT)) arr.push(Keyword.TAUNT);
    if (this.minion.hasKeyword(Keyword.DIVINE_SHIELD)) arr.push(Keyword.DIVINE_SHIELD);
    if (this.minion.hasKeyword(Keyword.POISONOUS)) arr.push(Keyword.POISONOUS);
    if (this.minion.hasKeyword(Keyword.WINDFURY)) arr.push(Keyword.WINDFURY);
    if (this.minion.hasKeyword(Keyword.REBORN)) arr.push(Keyword.REBORN);
    if (this.minion.hasKeyword(Keyword.CLEAVE)) arr.push(Keyword.CLEAVE);
    if (this.minion.hasKeyword(Keyword.DEATHRATTLE)) arr.push(Keyword.DEATHRATTLE);
    return arr;
  }

  private priceText(): string {
    const costs: number[] = [0, 3, 3, 4, 5, 5, 6];
    const idx = Math.min(Math.max(this.def().tier, 1), 6);
    return costs[idx].toString();
  }
}
