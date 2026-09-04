# 酒馆战棋 (HarmonyOS Battlegrounds)

一个使用 **HarmonyOS ArkTS (Stage 模型, API 12+)** 实现的炉石酒馆战棋风格单机自走棋卡牌游戏。

## 玩法

- 你与 AI 对手各拥有 40+ 血量的英雄
- 每回合获得金币（3→10 递增），用于：
  - **购买** 商店里的随从到手牌
  - **打出** 手牌随从到战场（最多 7 个）
  - **升级** 酒馆等级（解锁更强卡池）
  - **刷新** 商店、**冻结** 当前商店、使用英雄**技能**
- 三张同名随从自动合成 **金色（三连）** 版本，数值翻倍
- 准备就绪后点击 **战斗**，双方战场自动交战：
  - 嘲讽 / 圣盾 / 亡语 / 风怒 / 复生 / 剧毒 / 顺劈 全部忠实结算
  - 战斗过程逐帧回放，可见每一次攻击与触发
- 战败方按对手存活随从攻击力 + 酒馆等级扣血，血量归零即败

## 项目结构

```
entry/src/main/ets/
├── game/                      # 纯逻辑层（与 UI 解耦）
│   ├── model/                 # 数据模型
│   │   ├── Types.ets          # 种族 / 关键词 / 阵营枚举
│   │   ├── Trigger.ets        # 触发时机 / 效果 / 目标模型
│   │   ├── Minion.ets         # 随从定义(MinionDef)与实例(Minion)
│   │   └── Hero.ets           # 英雄定义与玩家状态
│   ├── data/                  # 卡牌库
│   │   ├── MinionLibrary.ets  # 36 张各等级随从
│   │   └── HeroLibrary.ets    # 6 位可选英雄
│   ├── combat/
│   │   ├── CombatTypes.ets    # 战斗事件 / 结果模型
│   │   └── BattleSimulator.ets# 自动战斗引擎
│   ├── engine/
│   │   ├── GameEngine.ets     # 主引擎：回合 / 商店 / 买卖 / 三连
│   │   └── AiController.ets   # AI 决策
│   ├── util/Rng.ets           # 可种子化随机
│   └── GameConfig.ets         # 规则常量
├── ui/
│   ├── Theme.ets              # 配色 / 尺寸主题
│   ├── Session.ets            # 跨页面会话
│   ├── components/            # 复用组件
│   │   ├── MinionCard.ets     # 随从卡
│   │   ├── HeroPanel.ets      # 英雄血量/金币面板
│   │   ├── ShopRow.ets        # 商店行
│   │   ├── HandRow.ets        # 手牌行
│   │   ├── BoardRow.ets       # 战场行
│   │   ├── BattleReplay.ets   # 战斗逐帧回放
│   │   └── ActionButton.ets   # 操作按钮
│   └── pages/                 # 页面（实际在 pages/ 下，见下）
├── pages/
│   ├── MainMenuPage.ets       # 标题 + 英雄选择
│   ├── GamePage.ets           # 主对局
│   └── ResultPage.ets         # 结算
└── entryability/EntryAbility.ets
```

## 构建与运行

环境要求：DevEco Studio（自带 HarmonyOS SDK）。

```bash
# 设置 SDK 路径（指向 DevEco 自带 SDK）
export DEVECO_SDK_HOME="C:/Program Files/Huawei/DevEco Studio/sdk"

# 构建 HAP 包
node hvigorw.js assembleHap --no-daemon
# 产物：entry/build/default/outputs/default/entry-default-unsigned.hap

# 或直接用 DevEco Studio 打开本目录，选择模拟器/真机运行
```

> 说明：本项目依赖通过 `.hvigor-deps/` 引用 DevEco 自带的 hvigor 引擎与插件，
> 无需联网下载。运行到设备需要先在 DevEco Studio 中下载对应的系统镜像并创建模拟器，
> 或连接真机（需开启开发者模式）。

## 设计要点

- **逻辑 / UI 完全解耦**：`game/` 下不引用任何 ArkUI 装饰器，可独立测试；
  战斗产出事件序列，UI 仅负责回放，互不耦合。
- **声明式触发器**：每张卡的技能用 `TriggerDef`(时机) + `EffectData`(效果/目标) 描述，
  引擎统一调度，新增卡牌无需改动战斗主循环。
- **ArkTS 严格类型合规**：所有对象字面量显式标注类型，避开 `arkts-no-untyped-obj-literals`，
  组件尺寸属性用 `cardWidth/cardHeight/isEnabled` 等避免与基类保留属性冲突。
