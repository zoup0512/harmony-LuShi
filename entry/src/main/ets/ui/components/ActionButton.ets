import { Theme } from '../Theme';
import { ArtAssets } from '../ArtAssets';

@Component
export struct ActionButton {
  @Prop label: string = '';
  @Prop sub: string = '';
  @Prop isEnabled: boolean = true;
  @Prop btnColor: string = Theme.GOLD_DIM;
  @Prop icon: string = 'skill';
  onTap: () => void = () => {};

  build() {
    Column({ space: 1 }) {
      Image(ArtAssets.action(this.icon)).width(21).height(21).opacity(this.isEnabled ? 1 : 0.55)
      Text(this.label).fontSize(12).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
      if (this.sub.length > 0) Text(this.sub).fontSize(8).fontColor(this.isEnabled ? '#FFE9A8' : Theme.TEXT_DIM)
    }
    .width(64).height(58).borderRadius(Theme.RADIUS_BUTTON)
    .backgroundColor(this.isEnabled ? this.btnColor : '#3A3A3A')
    .border({ width: 1.5, color: this.isEnabled ? Theme.GOLD : '#555555' })
    .justifyContent(FlexAlign.Center).opacity(this.isEnabled ? 1.0 : 0.55)
    .shadow({ radius: this.isEnabled ? 5 : 0, color: '#00000066', offsetX: 0, offsetY: 2 })
    .onClick(() => { if (this.isEnabled) this.onTap(); })
  }
}
