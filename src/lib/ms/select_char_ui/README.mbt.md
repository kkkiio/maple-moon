# `select_char_ui`

选人界面的独立 package。

职责：

- 在 `GamePhase::SelectCharacter` 时异步加载并创建选人 UI
- 显示背景、角色立绘和角色名字
- 处理 Select 按钮点击并发送 `SelectCharMessage`
- 监听 `SET_FIELD`，销毁 UI 并推进到游戏内场景

对外入口：

- `select_char_ui_system`
- `setup_game_server_handlers`
- `is_select_char_ui_open`（调试可见性）
- `list_debug_clickable_ids`（调试点击项列表）
- `click_debug_new_character`（调试触发创建角色）

## 接入示例

```moonbit nocheck
@select_char_ui.setup_game_server_handlers()

@system.App::new()
.add_system(
  @select_char_ui.select_char_ui_system,
  system_name="select_char_ui_system",
)
```
