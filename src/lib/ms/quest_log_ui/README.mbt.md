# quest_log_ui

`quest_log_ui` 提供任务日志窗口（Quest Log）的渲染与交互。

## 行为

- `Q` 键切换显示。
- `Esc` 关闭窗口。
- 目前支持 3 个 tab：
  - Tab0：进行中任务
  - Tab1：已完成任务
  - Tab2：预留占位（未启用）

## 使用方式

在主循环注册：

```moonbit nocheck
@quest_log_ui.quest_log_ui_system
```

该模块只依赖 `quest_log` facade，不直接读取 `quest` 内部结构。
