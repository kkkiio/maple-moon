# cursor

负责游戏鼠标光标渲染与状态同步。

## 行为

- 光标通过 `selene_ui` 渲染，层级固定为 `@graphics.CURSOR_ZINDEX`。
- 动画数据从统一的 aseprite atlas JSON 加载（`cursor_animation.json` + `cursor_animation.png`），
  每个 cursor 状态对应一个 frame tag，帧切换由 `CursorAnimationData::current_frame` 数据驱动。
- 光标状态由 `cursor_system` 单点计算：
  - 左键按下时 `CLICKING`
  - 命中可交互 UI 按钮或 world `Pickable` 时 `CAN_CLICK`
  - 其他情况 `IDLE`
- 不再支持外部命令式覆盖（已移除 `request_cursor_state`）。

## 初始化

在 AppResources 加载阶段调用：

```moonbit nocheck
let data = try! CursorAnimationData::load("assets/UI/Basic.img/Cursor/cursor_animation.json")
init_cursor(Cursor(data))
```

`CursorAnimationData::load` 会把 JSON 路径错误、JSON 结构错误、缺少动画帧等问题向上抛，
由 AppResources 的加载边界统一记录上下文并终止程序。

## 使用

在游戏循环中注册并执行：

```moonbit nocheck
@cursor.cursor_system(@time.delta())
```

## 资产

- `assets/UI/Basic.img/Cursor/cursor.aseprite`: Aseprite 源文件
- `assets/UI/Basic.img/Cursor/cursor_animation.json`: Aseprite packed spritesheet 描述
- `assets/UI/Basic.img/Cursor/cursor_animation.png`: Aseprite packed atlas PNG（301×197）
