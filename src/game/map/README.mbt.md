# Map

`ms/map` 使用 `Tiled`(`.tmj`) 地图资源.

## 资源入口

- `MapX/<mapId>.img/mx.json`
  - 仅包含 `tiled_path`
- `map.tmj`
  - 地图主体数据（`portal` / `life` / `foothold` / `ladderRope` / `seat` / `miniMap`）
  - Maple 背景字段保存在 `background_back_N` / `background_front_N` imagelayer 的 custom properties 中

## 运行时构建

- `load_map_resources_by_id`:
  - 读取 `mx.json` + `map.tmj` + 背景动画资源
- `create_scene_map`:
  - `from_tiled*` 直接投影到运行时类型：
  - `MapInfo`
  - `MapPortals`
  - `Physics`（经 `from_tiled_foothold_tree`）
  - `MiniMapRuntimeResource`

## 渲染路径

- 地图渲染统一走 `selene/tiled`：
  - `set_tiled_map(world, tiled_map, background_animations=...)`
  - `clear_tiled_map(world)`
  - `tiled_background_motion_system(world)`（Maple runtime 背景坐标/视差/平铺由本项目接管）
- Maple 背景有两条分支：
  - selene native branch：
    - 静态 `Normal(0)`
    - 静态 `HTiled(1)` 且 `cx == 0`
    - 静态 `VTiled(2)` 且 `cy == 0`
    - 静态表示 `ani != 1` 且没有 `a0/a1` alpha tween
    - 这些层还必须没有 Maple `rx/ry` 视差比率；否则要走 Maple runtime 的定位公式
    - native 层保留 Tiled imagelayer 生成的 image / repeat / parallax / opacity，Tiled 可做正常静态预览
  - Maple runtime branch：
    - `Tiled(3)`；虽然 `cx == 0 && cy == 0` 时几何上可连续平铺，但 selene imagelayer 以 map rectangle 作为 repeat extent，不能保证 Maple viewport-covering 语义
    - 所有移动类型 `HMoveA(4)` / `VMoveA(5)` / `HMoveB(6)` / `VMoveB(7)`
    - 所有 `cx/cy` 表示 Maple 离散间隔、不能等价为连续图片平铺的背景
    - 所有带 `rx/ry` Maple 视差比率的背景
    - 所有动画背景或 `a0/a1` alpha tween 背景
    - runtime 层会移除原 imagelayer sprite，用多个 child entity 表达 repeat
    - 动画按 layer state 采样一次当前帧，再同步到该层所有 tile child
- `repeatx/repeaty` 可服务 Tiled 静态预览；Maple runtime branch 以 `type/cx/cy/rx/ry/ani/a0/a1` 为事实来源。
- Maple runtime 背景：
  - `NxBackgroundType` 覆盖 `0..7`
  - 背景 repeat 使用多个 sprite entity，不依赖 `Sprite::Tiled`
  - 动画背景按层采样当前帧，再同步到该层所有 repeat tile
- `SceneMap` 保留字段：
  - `id`
  - `tiled_map`
  - `background_animations`
  - `life_spawns`
  - `physics`
  - `map_info`
  - `portals`
  - `mini_map_resources`
