---
name: maple-cli
description: 使用 Maple Moon 的 `maple`/`mapled` 命令行工具驱动浏览器客户端验证。用于需要检查游戏运行时、地图加载、资源加载、Victoria/Henesys smoke test、debug console 命令、failed network request、browser console error 或用户明确要求用 Maple CLI 验证浏览器状态时。
---

# Maple CLI

使用仓库里的 `src/cmd/maple` 和 `src/cmd/mapled` 操作本地浏览器客户端。优先让 CLI 产生可复现的运行时证据，不要用人工观察或普通构建结果代替地图/资源加载验证。

## 1. 准备客户端

在仓库根目录执行。先构建 Web 入口：

```bash
moon build --target js --release src/apps/game_web
```

检查 Vite 和 `mapled` 的所有权：

- 如果 `http://localhost:8080` 已可用，复用现有 Vite，不要结束它。
- 如果 Vite 不可用，由本次验证启动 `npm run dev`，结束后停止这个进程。
- 先运行 `moon run --target js src/cmd/maple status` 判断 `mapled` 是否已经存在。
- 如果 `mapled` 已由用户启动，复用它，不要关闭。
- 如果本次验证启动了 `mapled`，结束时运行 `moon run --target js src/cmd/maple close`。

## 2. 选择验证场景

默认 smoke test 使用 Victoria/Henesys：

- map id: `100000000`
- portal id: `0`
- frames: `300`

如果改动能从路径明确映射到地图资源，优先验证对应 map id。多个地图资源被改动时，最多选择 3 个代表地图，并在汇报中说明选择依据；无法明确映射时使用默认 Henesys。

## 3. 运行地图验证

启动或连接客户端：

```bash
moon run --target js src/cmd/maple start
```

验证默认 Henesys：

```bash
moon run --target js src/cmd/maple verify-map 100000000 0 --frames 300
```

验证指定地图时替换 `<map-id>` 和 `<portal-id>`：

```bash
moon run --target js src/cmd/maple verify-map <map-id> <portal-id> --frames 300
```

`verify-map` 会等待 debug console、必要时创建/选择角色、切换地图、推进帧，并输出状态。失败时保留输出摘要，重点报告 `failures` 和 `recentErrors`。

## 4. 检查网络和日志

地图验证后检查浏览器侧问题：

```bash
moon run --target js src/cmd/maple network --failed
moon run --target js src/cmd/maple logs --level error
```

如果存在 failed network request 或 browser console error，报告具体 URL、错误级别、消息摘要和与本次改动的关系。不要把这些问题静默降级为 warning。

## 5. 常用 CLI 操作

按需使用这些命令，不要在汇报中展开无关输出：

- `moon run --target js src/cmd/maple status`：查看 daemon/client 状态。
- `moon run --target js src/cmd/maple reload`：重新加载浏览器页面。
- `moon run --target js src/cmd/maple screenshot --out <path>`：保存当前画面。
- `moon run --target js src/cmd/maple cmd <name> [args...]`：执行游戏 debug console 命令，例如 `new_character`、`select_char 0`、`warp <map-id> <portal-id>`。
- `moon run --target js src/cmd/maple eval <js>`：执行浏览器侧 JavaScript，只在 CLI 命令不足以定位问题时使用。

## 6. 汇报格式

最终汇报包含：

- 验证的 map id / portal id / frames。
- `verify-map` 是否通过；失败时列出 `failures` 和 `recentErrors` 摘要。
- failed network request 检查结果。
- browser console error 检查结果。
- Vite 和 `mapled` 是复用还是本次启动，以及清理结果。
- 如果跳过或阻塞，给出具体原因，例如 Chrome 缺失、Node native `WebSocket` 不可用或 Vite 无法启动。
