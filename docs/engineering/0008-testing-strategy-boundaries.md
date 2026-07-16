# Testing Strategy & Boundaries

## Context

项目测试偏重视觉回归，缺乏游戏逻辑行为的自动化验证。同时，历史上出现过
手段被误用或 agent reward hacking 导致验证退化的情况。需要明确每种手段的
职责边界、禁止的用法、以及 agent 使用限制。

### 推动本决策的问题

- **`verify-map`**：maple-cli 被 agent 封装成复合命令，将多步操作坍缩为
  ok/fail。内部行为不透明，丧失原子操作的灵活性。
- **`visual_desc` 形骸化**：由 agent 编写和维护，形成"自己出题自己答"的
  循环论证，丧失参考价值。早期尝试用 Gemini Flash 3 做视觉语义判定，
  结果不稳定且 agent 倾向走捷径。
- **断言滥用**：`assert_true` 类断言容易被 agent 改为 trivially true。
  快照 baseline 为二进制数据，agent 难以低成本让 pixel 对比通过。
- **pixel 和 inspect 顺序不当**：pixel 先于 inspect 执行时，失败后
  agent 需要猜测是状态错还是渲染错，浪费诊断轮次。

## Decision

### 三种手段的职责边界

项目采用三种测试手段，各有独占覆盖维度，不重叠。

| 手段 | 覆盖维度 | 判定方式 | Baseline | Agent 权限 |
|------|----------|----------|----------|-----------|
| 快照测试 | 数据状态 → 视觉外观 | inspect 文本对比 → pixel 对比 | 有（JSON / PNG） | 编写测试 + 诊断失败 |
| maple-cli | 浏览器环境 | CDP 事件收集 | 无（只看 crash/404） | **仅原子操作** |
| Playtest Bot | 游戏逻辑行为 | 固定指标断言 | 无（遥测阈值） | **写策略 + 读报告，不写判定规则** |

### 问题类型 → 手段映射

每个问题类型只由一种手段负责。映射是设计决策，不随实现变化。

| 具体问题 | 快照测试 | maple-cli | Playtest Bot |
|----------|:--:|:--:|:--:|
| JS 异常 / 游戏崩溃 | — | ✅ | — |
| 资源 404 / 加载失败 | ✅ (像素差异) | ✅ (CDP Network) | — |
| Console error / WebGPU 错误 | — | ✅ | — |
| sprite 渲染错位/缺失 | ✅ | — | — |
| 图层 z-order 错误 | ✅ | — | — |
| UI 布局/遮挡 | ✅ | — | — |
| 动画帧选择错误 | ✅ | — | — |
| 数据结构回归（字段增减） | ✅ (inspect) | — | — |
| 传送门不触发 | — | — | ✅ |
| 绳索爬不上 | — | — | ✅ |
| 怪物不生成 | — | — | ✅ |
| 位置卡死/软锁 | — | — | ✅ |
| 掉落捡不起来 | — | — | ✅ |
| 伤害计算错误 | — | — | ✅ |
| UI 交互逻辑（按钮→界面切换→数据变化）| — | — | ✅ |
| 跨地图传送链（A→B→C→A）| — | — | ✅ |
| 性能退化（帧率、内存） | — | — | ✅ (可选) |
| 内存泄漏 / OOM | — | — | — |
| 音频/BGM 缺失 | — | — | — |

"—" = 非该手段覆盖范围

### 原则一：固定指标做裁判，AI 做分析

```
判定（机器执行）                    分析（AI 辅助）
├── pixel 对比 → pass/fail         ├── 对比 baseline vs wrong.png 诊断
├── inspect 对比 → pass/fail        ├── 分析遥测日志找根因
├── CDP error → pass/fail          └── 读代码定位 bug
├── 遥测指标 → pass/fail
└── 资源 status ≥ 400 → pass/fail
```

AI 的输出是建议，不是判决。判决权在固定指标。

任何可以被 AI 操控的模糊判定（如视觉模型看图打分）不作为测试 gate。

### 原则二：maple-cli 只提供原子操作

`maple` CLI 是原子命令的集合，每个命令做一件事：

```
maple start                 — 启动或复用 daemon
maple open                  — 默认打开 game_debug
maple open --entry web      — 打开普通 Web 入口
maple status                — 查看 daemon/client 状态与能力
maple act <domain> <verb>   — 执行一个有副作用的原子动作
maple observe [scope]       — 读取一个运行时状态快照
maple lookup <domain> ...   — 查询 resource-pack 静态数据
maple logs                  — 读取 console 日志
maple network               — 读取网络请求
maple screenshot            — 截图
maple debug command <...>   — 原始 console 调试入口
maple debug eval <js>       — 原始 JavaScript 调试入口
maple close                 — 关闭
```

不允许复合命令。验证流程由调用者组合原子操作完成，但调用者不得将组合
封装成新的黑盒命令。

例如，加载地图并检查错误的流程：
```bash
maple start
maple open --wait
maple act character create
maple act character select 0
maple act world warp 100000000
maple observe player
maple network --failed
maple logs --level error
```

### 原则三：移除 visual_desc

快照内容由文件路径和测试函数名自解释。例如
`char_look_test/__snapshot__/climb.png` + 测试名 `"character climbing ladder"`
已清楚表达图片内容。不需要额外的文字描述字段。

### 原则四：debug_inspect 先于 pixel snapshot

每个 graphics test 中，`@debug.debug_inspect` 必须在
`@capture_app.snapshot` 之前执行：

```moonbit
@debug.debug_inspect({ "sprite_count": sprites.size(), "stance": stance })
let capture = @capture_app.capture_after_frames(app, 1, width=200, height=200)
@capture_app.snapshot("src/graphics_test/__snapshot__/foo/scene.png", capture.png)
```

失败时 agent 先看 inspect diff 判断是状态层还是渲染层问题，再决定排查方向。

### 非目标

- 单元测试（`assert_true` 等逻辑断言）。对 agent reward hacking 抵抗力弱。
- AI 视觉模型自动化判定。已尝试，不稳定，放弃。
- 浏览器 WebGPU 图形快照测试。日常图形快照测试走 native raylib 后端；
  浏览器运行状态由 maple-cli 覆盖。

## Consequences

- 每种手段的边界清晰，选错手段的问题在 design review 阶段即可发现
- Agent 的 reward hacking 空间被压缩：快照 baseline 是二进制数据，
  固定指标是数值阈值，无法低成本让其"通过"
- maple-cli 回归原子操作后，agent 组合自由但不失控
- 引入 Playtest Bot 后，地图遍历、战斗、任务等逻辑行为首次有自动化覆盖

### Risks & mitigation

- **Agent 可能创造新的复合命令**：maple-cli 只有原子操作，agent 可能用
  shell 脚本或 skill 封装新黑盒。
  - *Mitigation*：code review 时识别非原子模式。
- **Playtest Bot 的固定阈值可能被 agent 调参 hack**：如将"卡死检测"
  阈值从 60帧调大到 600帧。
  - *Mitigation*：阈值定义在框架代码中，agent 策略代码无权修改。

## Alternatives Considered

- **保留 visual_desc 参数**。
  由 agent 自己写、自己改、自己看图判断，形成循环论证。

- **保留 AI 视觉模型自动判定**。
  Gemini Flash 3 判定不稳定，agent 倾向于更新快照而非排查问题。

- **让 agent 设计验证流程（verify-map 模式）**。
  导致不透明黑盒和 reward hacking。

- **加入大量单元测试**。
  逻辑断言对 agent reward hacking 抵抗力弱。维持快照 + CDP + bot 三种手段。
