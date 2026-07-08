---
name: maple-cli
description: 使用 Maple Moon 的 `maple`/`mapled` 原子命令操作浏览器。每个命令做一件事。用于需要检查浏览器状态、执行 console 命令、收集日志/网络、截图时。
---

# Maple CLI

maple-cli 提供原子操作命令，每个命令做一件事。验证流程由调用者（人类或 agent）
组合这些原子操作完成。

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
- 如果本次操作启动了 `mapled`，结束时运行 `moon run --target js src/cmd/maple close`。

## 2. 原子命令参考

```bash
# 启动/连接
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple status
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple close

# 执行 console 命令
moon run --target js src/cmd/maple cmd char_list
moon run --target js src/cmd/maple cmd new_character
moon run --target js src/cmd/maple cmd select_char 0
moon run --target js src/cmd/maple cmd warp 100000000 0
moon run --target js src/cmd/maple cmd meso 1000000
moon run --target js src/cmd/maple cmd item 1302007 1

# 读取日志/网络
moon run --target js src/cmd/maple logs
moon run --target js src/cmd/maple logs --level error
moon run --target js src/cmd/maple network
moon run --target js src/cmd/maple network --failed

# 截图/脚本
moon run --target js src/cmd/maple screenshot --out screenshot.png
moon run --target js src/cmd/maple eval "globalThis.$console.render_game_to_text()"
moon run --target js src/cmd/maple reload
```

## 3. 常用组合示例

以下为 agent 可自由组合的参考流程，不是固定命令。

**加载并检查一张地图**：

```bash
moon run --target js src/cmd/maple start
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple cmd char_list
# 如果无角色，创建并选择：
moon run --target js src/cmd/maple cmd new_character
moon run --target js src/cmd/maple cmd select_char 0
moon run --target js src/cmd/maple wait-ready
moon run --target js src/cmd/maple cmd warp 100000000 0
sleep 5                           # 等待游戏推进帧，shell 自带
moon run --target js src/cmd/maple network --failed
moon run --target js src/cmd/maple logs --level error
```

**检查网络和日志**：

```bash
moon run --target js src/cmd/maple network --failed
moon run --target js src/cmd/maple logs --level error
```

如果存在 failed network request 或 browser console error，报告具体 URL、错误级别、
消息摘要和与本次改动的关系。

## 4. 汇报格式

汇报包含：

- 执行的命令列表和结果摘要
- failed network request 检查结果
- browser console error 检查结果
- Vite 和 `mapled` 是复用还是本次启动，以及清理结果
- 如果跳过或阻塞，给出具体原因
