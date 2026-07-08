# quest_log_ui

`quest_log_ui` 提供任务日志窗口（Quest Log）的渲染与交互。

## 行为

- `Q` 键切换显示。
- `Esc` 关闭窗口。
- 双栏布局：
  - 左栏：任务列表（进行中/已完成 tab + 条目选择）
  - 右栏：任务详情（标题、阶段状态、摘要文本、按钮区）
- `FORFEIT` 按钮只在进行中任务可用，点击会调用 `@quest_log.forfeit(...)`。
- 目前支持 2 个 tab：
  - Tab0：进行中任务
  - Tab1：已完成任务
- 富文本标签支持：
  - 样式：`#b/#r/#k/#d/#g/#e/#n/#u`
  - 引用：`#t/#c/#p/#o/#m/#h`
  - 未识别结构标签（例如 `#L/#l`）按原文保留显示。
- 打开窗口后会向 `console` 注册可点击实体：
  - package: `quest_log`, ui: `tab.in_progress`
  - package: `quest_log`, ui: `tab.completed`
  - package: `quest_log`, ui: `row.in_progress.<n>`
  - package: `quest_log`, ui: `row.completed.<n>`

## 使用方式

在主循环注册：

```moonbit nocheck
@quest_log_ui.quest_log_ui_system
```

该模块依赖 `quest_log` facade 渲染任务数据，并复用 `markup_text`/`inventory` 做引用替换。
