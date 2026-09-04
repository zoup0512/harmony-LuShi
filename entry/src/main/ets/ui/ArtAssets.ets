import { Keyword, Tribe } from '../game/model/Types';

/** UI 视觉资源映射，游戏数据层不依赖 ArkUI Resource。 */
export class ArtAssets {
  static hero(id: number): Resource {
    switch (id) {
      case 1: return $r('app.media.hero_rafaam');
      case 2: return $r('app.media.hero_mukla');
      case 3: return $r('app.media.hero_nozdormu');
      case 4: return $r('app.media.hero_queen');
      case 5: return $r('app.media.hero_archon');
      default: return $r('app.media.hero_watcher');
    }
  }

  static tribe(tribe: Tribe): Resource {
    switch (tribe as number) {
      case 0: return $r('app.media.tribe_beast');
      case 1: return $r('app.media.tribe_demon');
      case 2: return $r('app.media.tribe_mech');
      case 3: return $r('app.media.tribe_dragon');
      case 4: return $r('app.media.tribe_murloc');
      case 5: return $r('app.media.tribe_element');
      case 6: return $r('app.media.tribe_pirate');
      default: return $r('app.media.tribe_neutral');
    }
  }

  static keyword(keyword: Keyword): Resource {
    switch (keyword) {
      case Keyword.TAUNT: return $r('app.media.icon_taunt');
      case Keyword.DIVINE_SHIELD: return $r('app.media.icon_shield');
      case Keyword.POISONOUS: return $r('app.media.icon_poison');
      case Keyword.WINDFURY: return $r('app.media.icon_windfury');
      case Keyword.REBORN: return $r('app.media.icon_reborn');
      case Keyword.DEATHRATTLE: return $r('app.media.icon_deathrattle');
      case Keyword.CLEAVE: return $r('app.media.icon_cleave');
      default: return $r('app.media.icon_skill');
    }
  }

  static action(name: string): Resource {
    switch (name) {
      case 'refresh': return $r('app.media.icon_refresh');
      case 'upgrade': return $r('app.media.icon_upgrade');
      case 'freeze': return $r('app.media.icon_freeze');
      case 'battle': return $r('app.media.icon_battle');
      default: return $r('app.media.icon_skill');
    }
  }
}

export const ART_BACKGROUND_MENU: Resource = $r('app.media.menu_background');
export const ART_BACKGROUND_GAME: Resource = $r('app.media.game_background');
export const ART_BACKGROUND_BATTLE: Resource = $r('app.media.battle_background');
export const ART_BACKGROUND_RESULT: Resource = $r('app.media.result_background');
export const ART_COIN: Resource = $r('app.media.icon_coin');
export const ART_ATTACK: Resource = $r('app.media.icon_attack');
export const ART_HEALTH: Resource = $r('app.media.icon_health');
export const ART_TAVERN: Resource = $r('app.media.icon_tavern');
