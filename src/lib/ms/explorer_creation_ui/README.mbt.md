# `explorer_creation_ui`

冒险家创建角色界面的独立 package。

职责：

- 在 `GamePhase::ExplorerCharacterCreation` 下异步加载并显示创建界面
- 管理性别选择、外观配置、确认创建三个阶段
- 异步加载角色预览并避免重复请求同一配置
- 发送 `CREATE_CHAR`
- 处理创建结果并返回 `SelectCharacter`

对外入口：

- `open_explorer_creation_ui`
- `close_explorer_creation_ui`
- `explorer_creation_ui_system`
- `setup_game_server_handlers`

测试约定：

- 不提供 `_for_test` 公共接口
- 黑盒测试通过正式 system、网络消息、副作用和快照完成
