# quest_log

`quest_log` 提供玩家任务日志的运行时快照与服务器同步入口。

- `setup(quests_resource)`：初始化模块。
- `setup_game_server_handlers()`：注册任务更新消息处理。
- `handle_player_quest_info(player_quests)`：应用 `SET_FIELD` 任务快照。
- `get_snapshot()`：获取用于 UI 渲染的任务列表快照。
- `revision()`：获取任务日志修订号。
- `current_player_quest_log()`：获取当前 `quest` 内部结构快照，供 `quest_icon` 等模块查询。
