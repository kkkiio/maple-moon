# npc_talk_ui

NPC 对话打开及异步加载期间暂停 gameplay action。手柄方向键移动选项焦点，
`South/A` 确认，`East/B` 走当前 `TalkAction` 的取消语义并向脚本回调 `None`。

负责 NPC 对话框的资源缓存、文本解析、按钮布局和点击交互。

## 富文本对话

对话正文和选项会复用 `selene/ui` 的段落布局 helper，支持英文自动换行，以及 Maple markup 里的颜色、粗体、下划线标签。

```moonbit nocheck
@npc_talk_ui.open_npc_talk_ui({
  npc_id: 1012102,
  speaker: @npc.Speaker::NPC_LEFT,
  str: "#bBlue#k text\n#e#uunderlined option#n",
  talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
})
```

## 运行时约束

- 使用前先通过 `cache_npc_talk_resource(...)` 缓存 `UtilDlgEx` 资源。
- 对话字符串中的引用标签依赖 `markup_text` 的预加载数据；未预加载时会继续抛错，不提供 fallback。

## 测试可观测性

`describe_npc_talk_ui()` 额外暴露以下字段，便于黑盒测试断言布局与层级：

- `window_size`：对话框窗口宽高（含 top/fill/bottom）。
- `window_rect`：窗口矩形边界（`left/top/right/bottom`）。
- `z_range`：当前对话框实体占用的最小/最大 z 值（聚合 sprite 与 selene_ui）。
