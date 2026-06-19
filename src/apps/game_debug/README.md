# apps/game_debug

Playtest Bot 验证专用的调试入口。基于 WebGPU (JS target)，在 `game_web` 的基础上
额外注册 `@bot_controller`，提供输入注入和 `globalThis.__bot` API。

## Build

```bash
moon build --target js --release src/apps/game_debug
```

## 与 game_web 的区别

| | game_web | game_debug |
|---|---|---|
| 用途 | 日常开发 | bot 自动化验证 |
| BotController | ❌ | ✅ |
| globalThis.__bot | ❌ | ✅ |
| 构建脚本 | `npm run dev` | mapled 单独加载 |
