# Playtest Bot — JS 场景脚本驱动的游戏行为测试

## Context

项目有三种测试手段（`0008-testing-strategy-boundaries.md`）：快照测试覆盖视觉/数据回归，maple-cli 覆盖
浏览器环境（crash/404/console error），两者都不覆盖游戏逻辑行为（传送、攀爬、
战斗、掉落等）。

maple-cli 曾被尝试用于让 coding agent 驱动游戏交互，效果不理想。根本原因是
agent 决策延迟（2-5秒/步）与游戏帧率（16ms）不匹配，无法玩动作游戏。

Playtest Bot 的设计目标：AI 编写 JS 场景脚本 → mapled 通过 CDP 注入浏览器 →
调用游戏暴露的 Promise API → 游戏侧 BotController 执行动作并检测完成 → 采集
遥测 → 固定指标判定。

## Decision

### game_debug：第三个游戏入口

在现有的 `game_web`（WebGPU，日常开发）和 `game_native`（raylib，玩家游玩）
之外，新增 `src/apps/game_debug/`：

```
src/apps/
├── game_web/          # WebGPU，日常浏览器开发
├── game_native/       # raylib，玩家本地游玩
└── game_debug/        # WebGPU，CLI automation 与 bot 开发入口
```

game_debug 复用 game_web 的平台 override（selene_webgpu），额外注册
BotController。`@app.run()` 是阻塞调用，BotController 必须在 App 构建期以 plugin
形式注入：

```moonbit
// src/apps/game_debug/main.mbt
fn main {
  let app = @game_app.base_app()
    .add_plugin(@plugins.default_plugin)
    .add_plugin(@console.plugin())
    .add_plugin(@game_app.game_systems())
    .add_plugin(@bot_controller.plugin())
  @ecs.set_current_world(app.world())
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  app.run()
}
```

`game_debug.html` 指向 `game_debug.js`；默认 `index.html` 仍然加载 `game_web.js`。
game_web 和 game_native 不注册 BotController。game_debug 在没有 pending
action 时不注入输入，允许玩家正常操作，并作为 `maple open` 的默认入口。

### 核心架构

```
┌────────────────────────────────────────────────────────────┐
│  浏览器（同一个 JS Runtime）                                  │
│                                                             │
│  ┌──────────────────────┐    ┌───────────────────────────┐ │
│  │ Game (game_debug)     │    │ Bot Script (纯 JS)         │ │
│  │                       │    │                            │ │
│  │  BotController ───────┼────┤  await __bot.warp(...)    │ │
│  │   每帧检查 action      │Promise│  await __bot.walk_to(...)  │ │
│  │   到达目标→resolve     │    │  await __bot.jump()        │ │
│  │   超时→reject+释放按键 │    │  await __bot.hold_up()     │ │
│  │                       │    │                            │ │
│  │  queue_input_snapshot │    │                            │ │
│  │  → Selene input queue │    │                            │ │
│  └──────────────────────┘    └───────────────────────────┘ │
│       ▲                                          │          │
│       │ CDP                                      │ CDP      │
│       ▼                                          ▼          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  mapled                                              │   │
│  │  - 启动 Chrome → 加载 game_debug                      │   │
│  │  - Runtime.evaluate 注入 JS bot 脚本                  │   │
│  │  - await Promise（阻塞直到脚本完成或超时）             │   │
│  │  - 收集 console / network / telemetry                 │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### Bot 脚本：纯 JS，零编译

AI 写的 bot 脚本是纯 JS async 函数，通过 CDP `Runtime.evaluate` 注入。
mapled 已具备这个能力：

```javascript
// AI 写的场景脚本 — mapled 会包一层 async wrapper
const bot = globalThis.__bot;

await bot.warp(100000000, 0);        // 传送到 Henesys
await bot.walk_to(1473, 260);        // 走到 waypoint
await bot.walk_to(2741, 259);        // 继续遍历主街

bot.telemetry.log("traversal complete");
return bot.state();
```

不需要 MoonBit 编译步骤，不需要产物注入，不存在符号冲突。

### 游戏侧：BotController

BotController 是 MoonBit 模块，仅在 game_debug 版本中注册。它提供：

**输入注入**：
BotController 每个 action frame 调用 `@runtime_debug.clear_queued_inputs()`，再通过
`@runtime_debug.queue_input_snapshot(snapshot)` 注入完整输入快照。这样驱动的是
player controller 的真实输入管道，同时 resolve/reject/timeout 时可原子释放 bot
按键。

**Action 管理**：
每个 `globalThis.__bot` 方法返回一个 JS Promise。BotController 在 Update
中检查当前 action 的完成条件：

| Action | 完成条件 |
|--------|----------|
| `walk_to(x,y)` | player 到达目标坐标附近 |
| `jump_forward()` | 起跳后落地 |
| `hold_up()` | 抓住绳索 / 触发传送门 / 地图切换 |
| `tap_key(code)` | 按住指定键一帧后释放 |
| `click_npc(npcId)` | 点击已加载 NPC 的碰撞框中心后释放鼠标 |
| `warp(map,portal)` | GamePhase 变为 GameActive |
| `attack_target(id)` | 目标 mob 从当前 `MapMobs` 中消失 |

**超时与取消**：
每个 action 附带 frame 超时。取消时 BotController 必须原子释放：清除 pending
injected snapshots，入队一个空 snapshot。不能逐个 `KeyUp` 排事件——已有 `KeyDown`
可能先被消费，导致残留输入跨帧泄漏。

**遥测**：
通过 `console.log("[playtest]", ...)` 发射，mapled CDP 收集。

### globalThis.__bot API

游戏侧通过 `extern "js"` FFI 暴露的接口（由 BotController 实现）：

```javascript
globalThis.__bot = {
  warp(mapId, portalId)    → Promise<void>,
  walk_to(x, y)            → Promise<void>,
  jump_forward()           → Promise<void>,
  hold_up()                → Promise<void>,
  tap_key(code)            → Promise<void>,
  click_npc(npcId)         → Promise<void>,
  attack()                 → Promise<void>,
  idle(frames)             → Promise<void>,

  // 查询
  state()                  → { pos, mapId, hp, state, ... },
  nearest_monster()        → Monster | null,
  nearby_portals()         → Portal[],

  // 遥测
  telemetry: { log(msg, data) },
};
```

### 集成 mapled

mapled 提供 `maple playtest` 子命令：

```bash
moon run --target native src/cmd/maple playtest run playtests/henesys_traversal.js

# 流程：
# 1. 构建 src/apps/game_debug
# 2. 读取 JS 脚本文件
# 3. 确保 game_debug.html 在浏览器中加载
# 4. CDP Runtime.evaluate 注入脚本（awaitPromise: true）
# 5. 等待 Promise resolve → report pass
# 6. error / 超时 / reject → 立即取消、report fail + telemetry、reload 页面
```

当前仓库包含六个场景：

- `playtests/enter_game.js`：验证角色进入有效地图并生成可控制玩家。
- `playtests/henesys_traversal.js`：进入 `100000000` Henesys，读取 portal 快照并走过多个主街 waypoint。
- `playtests/kill_monster.js`：进入 `100010000` Henesys Hunting Ground I，选择最近怪物并通过 `attack_target` 验证击杀。
- `playtests/world_map_smoke.js`：通过真实按键打开世界地图，验证父级导航和关闭清理。
- `playtests/world_map_routes.js`：验证字符串 map id 和 120/130/140 系列地图的数据驱动顶层页面路由。
- `playtests/shop_smoke.js`：通过 NPC 碰撞框注入真实鼠标点击，验证商店资源、商品和关闭清理。

### 遥测与判定

mapled 收集 console/network/telemetry 后，做固定指标判定（`0008-testing-strategy-boundaries.md` 原则一）：

- Bot 脚本 Promise reject → 失败
- console error / network failure → 失败
- action 超时 → 失败 + 卡死位置报告

本次脚本产生 browser error 时，mapled 立即取消脚本，不等待外层 deadline。任何失败
都会在保留诊断结果后 reload 页面，下一条 playtest 从干净运行时开始。

## Consequences

### Positive

- **AI 写脚本极简**：纯 JS async/await，线性编排，零编译
- **无符号冲突**：JS 注入不走 MoonBit 编译产物，不存在顶层符号冲突
- **CDP 注入即用**：mapled 已有 `Runtime.evaluate(awaitPromise: true)`
- **game_debug 干净**：debug system 只在调试版本注册，game_web/game_native 不受影响
- **输入注入走真实管道**：Selene deterministic input queue 驱动 controller，不 hack transform 或 DOM

### Risks & mitigation

- **BotController 的 action 完成检测依赖具体游戏逻辑**：walk_to 到达判定、
  攀爬抓住判定需要正确实现。
  - *Mitigation*：每个 action 先用手动测试验证完成语义正确，再加 bot 脚本
- **CDP 长任务管理**：bot 脚本可能跑很久，mapled socket 需要不超时。
  - *Mitigation*：mapled 的 bot 命令使用带剩余 deadline 的异步轮询；browser error
    会立即取消，失败后 reload 页面
- **action 残留**：timeout/reject 时必须保证释放所有按键。
  - *Mitigation*：BotController 在 resolve/reject/timeout 路径都清空 queued inputs，并入队空 snapshot

### Non-goals (for now)

- 视觉验证。由快照测试（`0002-use-native-raylib-for-graphics-snapshots.md`）负责。
- MoonBit 编写 bot 脚本。v0 用纯 JS，action 语义稳定后再考虑。
- 多人/多角色 bot 同时运行。
- CI 集成。
- 非 Web 平台（native raylib）。
