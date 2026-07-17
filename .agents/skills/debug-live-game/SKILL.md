---
name: debug-live-game
description: 使用 `just dev` 和 Maple CLI 复现、观察并诊断 Maple Moon 的运行时游戏问题。用于游戏行为、UI、输入、战斗、地图、资源加载或网络表现异常，用户表示 Dev Chrome 已出现问题现场，或 agent 需要启动 Dev Chrome 主动复现并收集 structured state、console、network、screenshot 证据时。仅执行已有测试或分析无需运行游戏的纯代码问题时无需使用。
---

# Debug Live Game

## 调试边界

- 把 `just dev` 视为 Dev Chrome 的唯一完整启动入口；它持有 watch build、Vite、`mapled`、controlled Chrome 和日志流。
- 把 Maple CLI 视为原子控制面；每个命令只观察或改变一个明确对象。
- 根据用户授权区分诊断与修复。用户只要求排查时，收集证据并报告根因，不修改实现。
- 从 `src/cmd/maple/README.md` 获取当前命令和参数；从 `docs/engineering/0006-add-maple-cli.md` 获取进程边界与命令语义。

## 接入 Dev Chrome

先判断是否存在用户正在查看的问题现场：

1. 用户表示问题当前就在 Dev Chrome 中时，直接接入现有会话。不要运行 `just dev`、`open`、`reload`、`act` 或 `logs --clear`，直到完成首轮观察。
2. 没有现成现场且问题需要运行游戏复现时，在支持长进程的前台终端中运行 `just dev`，保持该进程持续运行，并等待 Dev Chrome ready。
3. 使用 Maple CLI 查看状态；不要用 `maple start` 代替 `just dev`，因为它不启动 watch build 和 Vite。

```bash
moon run --target native src/cmd/maple status
```

用户已经保留现场时，只询问无法从游戏读取的信息，例如症状和最后一次人工操作。不要要求用户复制 Maple CLI 能直接读取的状态或日志。

## 先观察现场

根据症状选择最小的只读证据集。先读取 structured state，再读取相关日志、网络或画面：

```bash
moon run --target native src/cmd/maple observe summary
moon run --target native src/cmd/maple logs --level error
moon run --target native src/cmd/maple network --failed
moon run --target native src/cmd/maple screenshot --out /tmp/maple-moon-debug.png
```

- 使用 `observe player|inventory|npc_talk|full` 等贴近症状的 scope 深入检查；默认从 `summary` 开始。
- 视觉问题才截图，并实际查看图片内容。
- 保留原始 console 和 network ring buffer；收集现场证据前不要清空日志或重载页面。
- 把症状改写成一个可证伪断言，并用证据判断错误首先出现在哪个边界。

按证据收窄方向：

- Structured state 已错误：检查游戏状态、system 顺序、输入处理或服务端结果。
- Structured state 正确而画面错误：检查 presentation、sprite、资源和渲染层级。
- Network failure 或协议结果异常：检查请求、响应、客户端/服务端时序。
- Console exception：从首个业务异常追踪调用链，不从后续连锁错误开始修复。

## 主动复现与探测

优先使用稳定的 Maple CLI namespace：

- 使用 `lookup` 查询 map、NPC 和 item 的资源数据。
- 使用 `act` 执行一个有明确 postcondition 的游戏动作。
- 每次关键 `act` 后立即 `observe` 相关 scope，确定状态在哪一步开始偏离。
- 仅当 `act` 和 `observe` 无法表达所需能力时使用 `debug command` 或 `debug eval`，并说明缺少的稳定调试接口。
- 多步骤场景需要重复执行时，使用 `playtest run` 和 `playtests/` 中的场景脚本；保持 Maple CLI 命令原子化。

不要为了方便复现而先改变用户保留的问题现场。先完成首轮证据采集，再决定继续操作当前现场，或由 agent 建立一个新的复现路径。

## 验证结论

修复后利用 `just dev` 的 watch build 更新 Dev Chrome，按相同操作和观察点重新验证。只有需要重新加载新入口或重置运行状态时才执行 `reload`。

最终报告包含：

1. 可观察症状与可证伪断言。
2. Structured state、console、network、screenshot 中实际使用的证据。
3. 根因所在的代码或运行时边界。
4. 已执行的修复与复验结果；仅诊断时给出下一项最小验证实验。
