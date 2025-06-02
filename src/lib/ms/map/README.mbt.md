# Map

## 背景

- `front` 表示是否是前景，默认是 false
- `ani` 表示是否是动画，默认是 false

```mbt
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
  let map_tiles_objs_resource : BackgroundsResource = @json.from_json!(json)
  @json.inspect(map_tiles_objs_resource, content=[
    {
      "a": 255,
      "ani": false,
      "bS": "",
      "cx": 0,
      "cy": 0,
      "f": false,
      "front": false,
      "no": 0,
      "rx": 0,
      "ry": 0,
      "type_": { "$tag": "BG_NORMAL" },
      "x": 0,
      "y": 0,
    },
  ])
}
```
