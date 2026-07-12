# ms/mini_map_ui

小地图 UI 渲染模块，基于 Selene `@sprite.Sprite` 绘制窗口边框、地图画布与 portal marker。

## 主要职责

- 加载并解析小地图 UI 资源。
- 根据地图运行时数据（`MiniMapRuntimeResource`）绘制小地图内容。
- 在每帧系统中维护小地图 UI 对应的实体与位置同步。

## 资源来源

- UI 外框：`assets/UI/UIWindow2.img/MiniMap.json`
- Marker 图标：`assets/spritesheets/Map/MapHelper.img/minimap.json`
  - 当前要求包含 `portal/user/npc/another` 字段。
  - portal marker 使用 `minimap.portal`。

## 对外 API

- `mini_map_ui_system(delta)`：小地图 UI 系统，需注册到主循环。
- `set_current_map(map_id, map_name, street_name, mini_map_resources)`：设置当前地图小地图数据。
- `clear_current_map()`：清理当前地图绑定。

测试专用：

- `set_minimap_json_for_test(json)`
- `set_map_helper_minimap_json_for_test(json)`

## 与地图模块关系

- 本模块消费 `ms/map` 提供的 `MiniMapRuntimeResource`。
- 静态 portal marker 只渲染 `pt == 2`（`MiniMapPortalType::REGULAR`），与 OpenMapleClient 行为对齐。

## 接入示例

```moonbit nocheck
app.add_system(@mini_map_ui.mini_map_ui_system, system_name="mini_map_ui_system")
```

地图切换后更新：

```moonbit nocheck
@mini_map_ui.set_current_map(map_id, map_name, street_name, mini_map_resource)
```

## 渲染测试

- 黑盒渲染测试位于：`src/graphics_test/mini_map_ui_render_test.mbt`
- 快照输出目录：`src/graphics_test/__snapshot__/mini_map_ui/`
- 更新 PNG 快照：

```bash
MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```
