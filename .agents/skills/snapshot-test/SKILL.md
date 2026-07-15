---
name: snapshot-test
description: 编写/使用快照测试。快照包括 `@debug.debug_inspect` / `json_inspect` 数据快照和 `@capture_app.snapshot` 图片快照。数据快照必须在图片快照之前执行。快照内容由测试文件路径和函数名自解释，不需要 `visual_desc` 参数。
---

# Snapshot Test

## 测试原则

**先 inspect，后 pixel。先看状态对不对，再看画面对不对。**

快照测试由程序生成实际结果，再由人审查并批准。coding agent 负责选择要观察的行为，不要预先猜测只能通过运行实现才能知道的期望值。`moon test --update` 只生成候选 baseline；测试通过不代表该 baseline 已获批准，必须检查 diff 是否符合测试意图。

### 快照类型

| 原语 | 类型 | 用途 |
|---|---|---|
| `@debug.debug_inspect(value)` | 数据快照 | 验证具有稳定、可理解 `Debug` 表示的状态 |
| `json_inspect(value)` | 数据快照 | 验证原本就是 JSON 或具有业务含义 `ToJson` 表示的复杂对象 |
| `@capture_app.snapshot(path, png)` | 图片快照 | 验证渲染输出 |

### 固定顺序

每个 graphics test 中，数据快照必须在图片快照之前执行：

```mbt
// ✅ 正确顺序
@debug.debug_inspect(render_parts)
let capture = @capture_app.capture_after_frames(app, 1, width=200, height=200)
@capture_app.snapshot("src/graphics_test/__snapshot__/feature_name/scene.png", capture.png)
```

失败时先看 inspect diff 判断是状态层还是渲染层问题，再决定排查方向。

### 数据快照的观察对象

观察结果必须接近被测行为和业务语义，失败时能指向具体部件、资源或状态：

- 优先 inspect 函数的完整返回值、现有领域对象，或命名清楚且可复用的诊断投影。
- graphics test 只查询本测试拥有的 entity 子树或子系统。例如角色测试观察 body part、weapon、afterimage 的资源路径、可见性、layer 和 frame；UI 测试观察窗口状态、tab、文本行和图标；背景测试观察背景层、资源、alpha 和滚动模式。
- 角色、特效等渲染诊断优先从 capture metadata 投影实际提交的 sprites/draws，去掉 entity ID 后保留资源路径、source/destination rect、layer、颜色、翻转与位置。这样既能看到真正参与渲染的部件，也不会 dump 全局 registry 的运行时噪声。
- 诊断投影必须从实际运行状态产生。保留稳定且有解释力的字段，排除数字 entity ID、指针、runtime handle、偶然的集合顺序和无关瞬时状态。
- 不要直接 inspect 全局 sprites/entities registry，也不要默认给每个 graphics test 添加全局 entity/sprite 精确数量。只有数量本身是该测试稳定且可解释的行为时才保留。
- 多个值共同描述一个完整领域结果时可以组成一个快照；互不相关的观察值保持独立。
- `json_inspect` 用于原本就是 JSON 或具有业务含义 `ToJson` 表示的复杂对象。不要为了合并几个标量、断言或计数器而临时拼 JSON object。
- inspect baseline 由源码调用点定位。多个测试复用 setup/capture helper 时，helper 只构造并返回或传出诊断对象；每个具体测试必须在自己的唯一调用点执行 inspect，再执行图片快照。

### 反模式

- 不要把现有 `inspect` / `debug_inspect` / `json_inspect` 机械改成 `assert_eq` / `assert_true` / `assert_false`。普通断言只用于能从明确规格或不变量独立推导出的 expected。
- `debug_inspect(cond)` 只能说明谓词结果，通常应观察产生该结果的领域状态；不要为了消除布尔快照而机械改成普通断言。
- 不要为了合并独立观察项而临时构造 JSON object。
- 不要把会产生不同结果的多个测试汇聚到 helper 内同一个 inspect 调用点。
- 不要在 pixel snapshot 之前漏掉 `debug_inspect`
- 不要填写 `visual_desc` 参数（已废弃）

## 文本快照

使用 `@debug.debug_inspect` / `json_inspect` 做数据快照，不要自己填写 `content` 参数。
首次创建或更新数据快照时，使用 `moon test --update` 让 MoonBit 写入 inspect baseline。

未知或由实现产生的结果必须先写无 `content` 的 inspect，再运行测试生成 baseline。不要读取当前输出后把它手写进 `assert_eq`。已有数据快照也保持快照工作流；Debug 文本发生合理变化时审查并更新 baseline。

```mbt
@debug.debug_inspect(some_value)
json_inspect(@npc_talk_ui.describe_npc_talk_ui())
```

如果修改了代码导致 inspect 快照不通过，用 `moon test --update` 更新快照，并检查快照是否正确。PNG 快照不读取 `--update`，只读取 `UPDATE_GRAPHICS_SNAPS=true`。

## 图片快照

按以下流程执行，直到 pixel 对比通过。

### 1. 写图形快照测试

- 在 `src/graphics_test/` 下编写图形快照测试（所有图形测试共享一个 package）。
- 该 package 使用 native target 和 `Milky2018/selene_raylib/*` platform overrides。
- 用 `@capture_app.capture_after_frames` 初始化测试 App，挂上 `@plugins.default_plugin` 和被测系统。
- 如果测试在 `capture_after_frames` 之前会加载 raylib texture，先调用 `@capture_app.ensure_native_context(width=..., height=...)`。
- 测试里直接读取本地 `assets/...json` 并传给游戏模块解析。
- 不为测试改正式资源加载链路。
- 固定画布尺寸、UI 位置、输入和帧推进次数，保证快照稳定可复现。
- 测试文件路径和测试函数名应清晰表达图片内容（如 `__snapshot__/char_look/climb.png` + 测试名 `"character climbing ladder"`）。
- 在 pixel snapshot 之前写 `@debug.debug_inspect`。

### 2. 首次生成快照（仅新测试）

**仅在新增测试、尚未有 baseline PNG 时**使用 `UPDATE_GRAPHICS_SNAPS=true` 写入初始快照。严禁用该变量消除已有测试的 pixel mismatch 失败——mismatch 必须先诊断 `.wrong.png` 差异，确认是预期视觉变化后再更新。

在仓库根目录执行：

```bash
MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```

如果同一次改动还新增或改变了 `debug_inspect` / `json_inspect` baseline，另跑 inspect 更新：

```bash
MOONBIT_NEW_NATIVE=1 moon test --target native --update --deny-warn --diagnostic-limit 200 src/graphics_test
```

### 3. agent 检查快照图片

- agent 打开本次生成的 PNG baseline 并逐张检查。
- 重点检查：是否空白、错位、缺层、方向错误、锚点异常、透明度异常。
- 检查通过 → commit baseline。

### 4. 若不通过，定位问题

1. 先看 `debug_inspect` diff，确认内部状态是否一致
2. 再看 pixel diff（baseline vs .wrong.png），确认渲染差异
3. 定位业务代码：渲染顺序、姿态映射、字段解析、动画帧选择、坐标/翻转逻辑

**严禁在未诊断 `.wrong.png` 的情况下直接 `UPDATE_GRAPHICS_SNAPS=true` 覆盖 baseline。** 覆盖 baseline 仅在确认改动是预期视觉变化（如改坐标系、换渲染层）且手工人眼确认 `.wrong.png` 正确后才允许。

### 5. 退出条件

- 无更新复跑通过：

```bash
MOONBIT_NEW_NATIVE=1 moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```

> **注意**：纯逻辑测试（如 `mapled_protocol`）直接在源码包内写 blackbox test（`*_test.mbt`），不放入 `graphics_test`。
