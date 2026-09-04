/**
 * 酒馆战棋 - UI 主题
 *
 * 集中定义配色与尺寸，让所有组件保持视觉一致。
 * 采用深色"炉石酒馆"风格：暗木背景、金色描边、宝石色随从卡。
 */

export class Theme {
  // 背景
  static readonly BG_DEEP: string = '#0E1A2B';      // 最底层背景
  static readonly BG_TAVERN: string = '#1B2A45';    // 酒馆主面板
  static readonly BG_PANEL: string = '#243757';     // 子面板
  static readonly BG_PANEL_LIGHT: string = '#2E4467';
  static readonly BG_GLASS: string = '#D91A2940';
  static readonly BG_GLASS_DARK: string = '#E60A1220';
  static readonly SCRIM: string = '#99040A14';
  static readonly FROST: string = '#A82D91B5';

  // 描边与金属
  static readonly GOLD: string = '#D4A84B';
  static readonly GOLD_DIM: string = '#8A6B2A';
  static readonly SILVER: string = '#C8D2E0';

  // 文字
  static readonly TEXT_PRIMARY: string = '#F5E9C9';
  static readonly TEXT_SECONDARY: string = '#A9B4C6';
  static readonly TEXT_DIM: string = '#6B7790';

  // 状态色
  static readonly HP_GREEN: string = '#3DBB4F';
  static readonly HP_YELLOW: string = '#E2C044';
  static readonly HP_RED: string = '#D8483B';
  static readonly ATTACK_RED: string = '#E25555';
  static readonly GOLD_COIN: string = '#F2C94C';

  // 种族主题色（卡牌背景渐变依据）
  static readonly TRIBE_COLORS: Record<string, string> = {
    '0': '#6B8E3D', // 野兽 绿
    '1': '#7B2D8F', // 恶魔 紫
    '2': '#B8860B', // 机械 黄铜
    '3': '#C0392B', // 龙 红
    '4': '#2E86AB', // 鱼人 蓝
    '5': '#E67E22', // 元素 橙
    '6': '#34495E', // 海盗 深灰蓝
    '7': '#566573'  // 中立 灰
  };

  // 关键词徽章色
  static readonly KW_TAUNT: string = '#7F8C8D';
  static readonly KW_SHIELD: string = '#F1C40F';
  static readonly KW_POISON: string = '#27AE60';
  static readonly KW_WINDFURY: string = '#E74C3C';
  static readonly KW_REBORN: string = '#9B59B6';
  static readonly KW_DEATHRATTLE: string = '#34495E';
  static readonly KW_CLEAVE: string = '#C0392B';

  // 尺寸
  static readonly CARD_W: number = 92;
  static readonly CARD_H: number = 124;
  static readonly CARD_W_BIG: number = 110;
  static readonly CARD_H_BIG: number = 150;
  static readonly RADIUS_CARD: number = 10;
  static readonly RADIUS_BUTTON: number = 8;

  /** 根据种族枚举值取主题色 */
  static tribeColor(tribeValue: number): string {
    return Theme.TRIBE_COLORS[tribeValue.toString()] || Theme.TRIBE_COLORS['7'];
  }

  /** 根据血量百分比返回颜色（绿→黄→红） */
  static hpColor(ratio: number): string {
    if (ratio > 0.6) return Theme.HP_GREEN;
    if (ratio > 0.3) return Theme.HP_YELLOW;
    return Theme.HP_RED;
  }
}
