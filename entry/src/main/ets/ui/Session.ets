/**
 * 酒馆战棋 - 全局会话管理
 *
 * 由于 ArkTS 页面间默认不共享复杂对象状态，用一个全局单例持有 GameEngine，
 * 供主菜单创建、游戏页使用、结算页读取结果。
 */

import { GameEngine } from '../game/engine/GameEngine';
import { HeroDef } from '../game/model/Hero';

export class Session {
  private static instance: GameEngine | null = null;
  /** 上一局是否获胜（结算页用） */
  static lastWon: boolean = false;
  /** 上一局回合数 */
  static lastRound: number = 0;

  static start(hero: HeroDef): GameEngine {
    Session.instance = new GameEngine(hero);
    return Session.instance;
  }

  static get(): GameEngine | null {
    return Session.instance;
  }

  static clear(): void {
    Session.instance = null;
  }
}
