---
name: snapshot-test
description: 编写/使用快照测试. 快照包括`inspect`/`json_inspect` moonbit 原生文本快照和 `@capture_app.snapshot` 图片快照. 快照断言不需要填写内容, 由测试第一次运行时自动生成. 图片快照适用于角色渲染、地图层级、特效、UI 画面等“代码正确但视觉可能错误”的场景.
---

# Snapshot Test

## 文本快照

使用 `inspect`/`json_inspect` 做文本快照断言, 不要自己填写 `content` 参数, 执行 `moon test` 第一次运行时会自动生成快照.

```mbt
json_inspect(@npc_talk_ui.describe_npc_talk_ui())
```

```mbt
json_inspect(@npc_talk_ui.describe_npc_talk_ui(), content={
    "open": true,
    "body_lines": [
        "Ah~! It is really getting to me!!! Blue Mushroom... Oh... Are you a stranger?",
    ],
    "selections": [],
    "button_count": 2,
    "choice_area_count": 0,
    "window_pos": { "x": 141, "y": 202 },
    "body_height": 76,
})
```

如果修改了代码, 导致快照不通过, 用 `moon test --update` 更新快照, 并检查快照是否正确.

## 图片快照

按以下固定流程执行，直到“自动测试通过 + agent 看图判定通过”。

### 1. 写渲染快照测试

- 在 `src/test/<feature>_test/` 下新建或更新 blackbox test 包。
- 复用 `capture_backend` override（对齐测试包 `moon.pkg` 配置）。
- 用 `@capture_app.init_app(...)` 初始化测试 App，挂上 `@plugins.default_plugin` 和被测系统。
- 测试里直接读取本地 `assets/...json` 并传给游戏模块解析。
- 不为测试改正式资源加载链路（例如 `src/lib/resource/load.mbt`）。
- 让“测试注入”和“正式流程”复用同一份解析函数，避免双份解析逻辑。
- 固定画布尺寸、UI 位置、输入和帧推进次数，保证快照稳定可复现。
- 调用 `@capture_app.snapshot(".../__snapshot__/xxx.png")` 产出或比对 PNG。

### 2. 执行测试生成快照

在仓库根目录执行：

```bash
source .env.test && UPDATE_CANVAS_SNAPS=true moon test <test-target>
```

### 3. 由 agent 查看快照图片并判定

- agent 必须打开本次生成的 PNG 快照并逐张检查。
- 重点检查：是否空白、错位、缺层、方向错误、锚点异常、透明度异常。
- 判定结果记录为“通过/不通过”，并附问题图片路径与现象描述。

### 4. 若不通过，分析并定位问题

- 先检查测试稳定性：帧推进、实体位置、资源加载时序。
- 再定位业务代码：渲染顺序、姿态映射、字段解析、动画帧选择、坐标/翻转逻辑。
- 必要时添加最小范围日志或断言。

## 5. 退出条件

仅当同时满足以下条件才结束：

- `source .env.test && moon test <test-target>` 通过。
- agent 对快照图片判定为通过。
