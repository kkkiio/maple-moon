# Map

`ms/map` 现在是严格的 TMJ 主链路，不再提供旧 `NxMap` 背景/Tile/Obj 渲染路径。

## 资源入口

- `MapX/<mapId>.img/mx.json`
  - 仅包含 `tiled_path`
- `map.tmj`
  - 地图主体数据（`portal` / `life` / `foothold` / `ladderRope` / `seat` / `miniMap`）

## 运行时构建

- `load_map_resources_by_id`:
  - 读取 `mx.json` + `map.tmj`
- `create_scene_map`:
  - `from_tiled*` 直接投影到运行时类型：
  - `MapInfo`
  - `MapPortals`
  - `Physics`（经 `from_tiled_foothold_tree`）
  - `MiniMapRuntimeResource`

## 渲染路径

- 地图渲染统一走 `selene/tiled`：
  - `set_tiled_map`
  - `clear_tiled_map`
  - `tiled_background_motion_system`（仅补 `type4/type5` Maple 背景运动）
- `SceneMap` 保留字段：
  - `id`
  - `tiled_map`
  - `life_spawns`
  - `physics`
  - `map_info`
  - `portals`
  - `mini_map_resources`
