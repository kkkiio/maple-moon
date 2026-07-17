# `ms/world_map_ui`

大地图 UI。

当前实现目标：

- 加载 `UIWindow2.img/WorldMap`、`UIWindow2.img/ToolTip.WorldMap`
- 加载 `MapHelper.img/worldMap` marker
- 加载 `Map/WorldMap/*.img/nx.json`
- 支持打开/关闭、`MapLink` 切页、`MapSpot` hover/path overlay
- 键盘 `W` 或手柄 `Select` 打开，`Escape` / `East/B` 返回上一级或关闭
- 大地图可见期间暂停 gameplay action，关闭及场景清理时释放输入上下文

资源依赖：

- `res://UI/UIWindow2.img/WorldMap/nx.json`
- `res://UI/UIWindow2.img/ToolTip/nx.json`
- `res://Map/MapHelper.img/worldMap/nx.json`
- `res://Map/WorldMap/<page>.img/nx.json`

测试时可通过 `set_*_for_test` API 直接注入 JSON，避免改正式 loader。

## 接入示例

```moonbit nocheck
@system.App::new()
.add_system(@world_map_ui.world_map_ui_system, system_name="world_map_ui_system")

@world_map_ui.set_current_map(100000000, "Henesys", "Victoria Road")
@world_map_ui.set_world_map_visible(true)
```
