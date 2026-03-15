# Quest Icon Package

`quest_icon` 包负责地图内 NPC 头顶任务图标的渲染与交互。

职责：

- 加载 `UIWindow2.img/QuestIcon` 资源并创建图标子实体。
- 根据 quest 查询结果为 NPC 显示/隐藏图标。
- 处理鼠标命中与点击，点击后发起 quest 对话请求。

不负责：

- 任务条件判定与任务日志维护（由 `quest` 包负责）。
- NPC 普通对话状态机（由 `npc` / `npc_talk_ui` 负责）。

主要 API：

- `set_context(query_npc_icon, build_quest_talk_args)`
- `clear_context()`
- `quest_icon_system(delta)`
