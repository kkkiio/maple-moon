# Map

其结构主要包含:

- `info`: 地图元数据 (背景音乐 bgm, 是否游泳 swim, 限制等)
- `back`: 背景图层
- `life`: NPC 和怪物
- `portal`: 传送门信息
- `foothold`: 地形/物理碰撞信息

## 背景

- `front` 表示是否是前景，默认是 false
- `ani` 表示是否是动画，默认是 false

```mbt
///|
test {
  let json : Json = {
    "0": {
      "a": 255,
      "bS": "",
      "cx": 0,
      "cy": 0,
      "no": 0,
      "rx": 0,
      "ry": 0,
      "type": 0,
      "x": 0,
      "y": 0,
    },
  }
  let map_tiles_objs_resource : BackgroundsResource = @json.from_json(json)
  inspect(
    map_tiles_objs_resource,
    content=(
      #|BackgroundsResource([{a: 255, ani: false, bS: "", cx: 0, cy: 0, f: false, front: false, no: 0, rx: 0, ry: 0, type_: BG_NORMAL, x: 0, y: 0}])
    ),
  )
}
```
