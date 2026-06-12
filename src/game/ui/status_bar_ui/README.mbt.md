# Status Bar UI

`status_bar_ui` 提供基于 selene sprite 的常驻 HUD。

当前版本先以文字 HUD 替代旧 `@ui.Widget` 状态栏，直接从 `@player.get_player()` 读取角色属性，并在主循环里通过 `status_bar_ui_system` 渲染。

## 用法

在主循环注册：

```moonbit nocheck
@status_bar_ui.status_bar_ui_system
```

系统会在 `GameActive` 阶段自动显示，离开游戏场景后自动清理。
