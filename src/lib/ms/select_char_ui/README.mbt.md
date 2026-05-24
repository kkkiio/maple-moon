# `select_char_ui`

选人界面的独立 package。

职责：

- 在 `GamePhase::SelectCharacter` 时加载并创建选人 UI
- 显示背景、角色立绘和角色名字
- 处理 Select 按钮点击并发送 `SelectCharMessage`
- 监听 `SET_FIELD`，销毁 UI 并推进到游戏内场景

对外入口：

- `select_char_ui_system`
- `setup_game_server_handlers`
- `is_select_char_ui_open`（调试可见性）

调试点击：

- 该模块会在创建/销毁 UI 时自动向 `console` 注册/反注册实体：
  - package: `select_char`
  - ui: `new_character`

## 接入示例

```moonbit nocheck
@select_char_ui.setup_game_server_handlers()

@system.App::new()
.add_system(
  @select_char_ui.select_char_ui_system,
  system_name="select_char_ui_system",
)
```
