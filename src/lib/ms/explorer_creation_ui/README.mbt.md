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

## 接入示例

```moonbit nocheck
@explorer_creation_ui.setup_game_server_handlers()
@explorer_creation_ui.open_explorer_creation_ui(char_look_mod)

@system.App::new()
.add_system(
  @explorer_creation_ui.explorer_creation_ui_system,
  system_name="explorer_creation_ui_system",
)
```
