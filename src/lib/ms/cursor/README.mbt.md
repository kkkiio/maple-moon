# cursor

负责游戏鼠标光标渲染与状态同步。

## 行为

- 光标通过 `selene_ui` 渲染，层级固定为 `@graphics.CURSOR_ZINDEX`。
- 光标状态由 `cursor_system` 单点计算：
  - 左键按下时 `CLICKING`
  - 命中可交互 UI 按钮或 world `Pickable` 时 `CAN_CLICK`
  - 其他情况 `IDLE`
- 不再支持外部命令式覆盖（已移除 `request_cursor_state`）。

## 使用

在游戏循环中注册并执行：

```moonbit nocheck
@cursor.cursor_system(@time.delta())
```
