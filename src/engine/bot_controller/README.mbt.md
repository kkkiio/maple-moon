# bot_controller

Playtest Bot 的引擎侧运行时。仅在 `game_debug` 构建中注册，提供：

- **输入注入**：通过 Selene deterministic input queue 将 bot 按键写入游戏输入管道
- **Action 管理**：接收 JS bot 脚本的 Promise-based action，在 Update 中检测完成
- **globalThis.__bot API**：暴露 `walk_to`、`jump_forward`、`hold_up`、`warp` 等 Promise 方法

## Public API

- `plugin()` — 返回 `@app.Plugin`，供 `game_debug` 入口注入
- `install()` — 挂载 `globalThis.__bot`（Startup 阶段调用）

## Integration

仅在 `src/apps/game_debug/` 中通过 `@game_app.base_app().add_plugin(@bot_controller.plugin())` 注册。
`game_web` 和 `game_native` 不使用此包。

## 输入注入机制

使用 Selene 的 `@runtime_debug.queue_input_snapshot(snapshot)` 将完整按键快照注入 deterministic input queue。
每个 action frame 都会先 `clear_queued_inputs()`，再入队当前 bot-owned keys 的 snapshot；resolve/reject/timeout 时入队一个空 snapshot，避免残留按键跨帧泄漏。

## Action 完成语义

每个 action 在 `Update` 中逐帧检查完成条件：
- `walk_to` → player 到达目标坐标
- `jump_forward` → 起跳后落地
- `hold_up` → 抓住绳索或触发传送
- `warp` → GamePhase 变为 GameActive
- `attack_target` → 目标 mob 从当前 `MapMobs` 中消失
