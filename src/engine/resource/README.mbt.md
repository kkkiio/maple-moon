# Resource

定义资源 loader 接口与运行时 loader 注册表。上层 package（例如 `apps/game`）负责安装具体 loader。

约束：

- 通用树形资源（`AsyncLoader::load_resource`）不做业务缓存。
- 文件路径资源如果必须存在，使用 `AsyncLoader::require_data` 直接读取 JSON；
  `AsyncLoader::load_data` 是兼容别名。
- 图片资源统一通过 `AsyncLoader::load_image` 加载。
- 直接读取 JSON 文件时，使用 `load_json(path)` 让错误向上抛；使用
  `require_json(path)` 表示资源必须存在且允许立即终止程序。
- 直接读取图片文件时，使用 `require_image(path)` 表示资源必须存在；
  `load_image(path)` 仅作为兼容别名保留。
- 路径解析统一由 package 内部 resolver 处理：resolved asset path 使用 `assets/...`，禁止 leading-slash 路径(`/...`)和 `http(s)` 路径。
- source-relative 输入（例如 `Consume/0200.img`）由对应 loader source 映射到 `assets/...`。
- file-relative 引用（例如 Aseprite `animation.png`、Tiled `../../tilesets/foo.tsj`）相对声明文件路径解析。
- `resolve_ref(base_path, ref_path)` 可把声明文件中的相对引用一次性归一为 resolved asset path（`assets/...`）。
- `resolve_json_resource_path(source, path)` 只解析 JSON 资源读取目标，返回 JSON 文件路径和文件内节点路径，不负责读取或解析 JSON。
- `@resource.load_image(path)` 只接受 resolved asset path（`assets/...`）；业务代码通常应使用 `AsyncLoader::load_image(path)` 处理 source-relative 输入。
- 不要把 `/assets/...` 传给 `@asset.load_image`、`@asset.read_bytes` 或本地 `@fs`。
- Aseprite/NX 导出动画通过 `AnimationLoader` 在本包内做编译结果缓存（key 为规范化后的 `animations_path`），避免重复构图与注册资产。
- packed spritesheet 以 `meta.size` 表示整张 atlas 尺寸，单帧 `frame` 表示 atlas rect，`sourceSize` 表示该 clip 的逻辑帧尺寸；不同 `frameTags` 可以有不同逻辑尺寸。

## 接入示例

```moonbit nocheck
@resource.register_async_loader("mapx", my_map_loader)
@resource.register_async_loader("npc", my_npc_loader)

let map_loader = @resource.get_async_loader("mapx")
let raw = map_loader.require_resource(["Map1", "100000000.img.mx.json"])
let npc_loader = @resource.require_async_loader("npc")
let mx_path = "Npc/Npc/0002007.img/mx.json"
let mx = npc_loader.require_data(mx_path)
let anim_path = @resource.resolve_ref(
  npc_loader.resolve_json_path(mx_path),
  "animation.json",
)
let image = @resource.require_image("assets/UI/Basic.img/Cursor/cursor_animation.png")
ignore(mx)
ignore(image)
ignore(anim_path)
```

## 错误处理边界

```moonbit nocheck
let optional = try! @resource.load_json("assets/UI/Basic.img/Cursor/cursor_animation.json")
let required = @resource.require_json("assets/UI/Basic.img/Cursor/cursor_animation.json")
ignore(optional)
ignore(required)
```

- `load_json(path)` 返回 `Json? raise`：文件不存在返回 `None`，路径非法或 JSON
  损坏时抛错，适合底层 loader 或需要由 system 统一记录上下文的调用链。
- `require_json(path)` 返回 `Json`：路径非法、文件不存在、JSON 损坏都会终止程序，
  只用于预定义且不可缺失的运行时资源。
- `fetch_json(path)` 是旧接口；新代码优先选择 `load_json` 或 `require_json`。

## JSON 资源路径

```moonbit nocheck
///|
test "resolve item json file and node path" {
  let (file_path, node_path) = @resource.resolve_json_resource_path(
    "item", "Consume/0200.img/02000000",
  )
  inspect(file_path, content="assets/Item/Consume/0200.img.json")
  inspect(node_path, content="[\"02000000\"]")
}
```

## Aseprite 动画

```moonbit nocheck
let npc_loader = @resource.require_async_loader("npc")
let animation_loader = AnimationLoader(npc_loader)
let loaded = animation_loader.load("Npc/Npc/0002007.img/animation.json")
let stand = loaded.clip("stand")
ignore(stand)
```
