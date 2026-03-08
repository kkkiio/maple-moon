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

测试约定：

- 渲染回归使用 `@capture_app.snapshot(...)`
- 调试状态通过 package 内的测试辅助函数导出，避免直接依赖内部实体细节
