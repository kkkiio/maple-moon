---
name: snapshot-test
description: 编写/使用快照测试。快照包括 `@debug.debug_inspect` / `json_inspect` 数据快照和 `@capture_app.snapshot` 图片快照。数据快照必须在图片快照之前执行。快照内容由测试文件路径和函数名自解释，不需要 `visual_desc` 参数。
---

# Snapshot Test

## 测试原则

**先 inspect，后 pixel。先看状态对不对，再看画面对不对。**

### 快照类型

| 原语 | 类型 | 用途 |
|---|---|---|
| `@debug.debug_inspect(value)` | 数据快照 | 验证内部状态（sprites、entities、UI 数据等） |
| `json_inspect(value)` | 数据快照 | 结构化 JSON 快照 |
| `@capture_app.snapshot(path, png)` | 图片快照 | 验证渲染输出 |

### 固定顺序

每个 graphics test 中，数据快照必须在图片快照之前执行：

```mbt
// ✅ 正确顺序
@debug.debug_inspect({
  "sprite_count": @sprite.sprites().size(),
  "stance": look.current_stance,
})
let capture = @capture_app.capture_after_frames(app, 1, width=200, height=200)
@capture_app.snapshot("src/graphics_test/__snapshot__/feature_name/scene.png", capture.png)
```

失败时先看 inspect diff 判断是状态层还是渲染层问题，再决定排查方向。

### 反模式

- 不要把快照当布尔断言用（`debug_inspect(cond, content="true")`）
- 不要在 pixel snapshot 之前漏掉 `debug_inspect`
- 不要填写 `visual_desc` 参数（已废弃）

## 文本快照

使用 `@debug.debug_inspect` / `json_inspect` 做数据快照，不要自己填写 `content` 参数。
首次创建或更新数据快照时，使用 `moon test --update` 让 MoonBit 写入 inspect baseline。

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
