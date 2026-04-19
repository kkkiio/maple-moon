# Resource

定义资源 loader 接口与运行时 loader 注册表。上层 package（例如 `apps/game`）负责安装具体 loader。

约束：

- 通用树形资源（`AsyncLoader::load_resource`）不做业务缓存。
- 文件路径资源可使用 `AsyncLoader::load_data` 直接读取 JSON。
- 图片资源统一通过 `AsyncLoader::load_image` 加载。
- 路径解析统一由 package 内部 resolver 处理：允许绝对路径(`/...`)，禁止 `http(s)` 路径。
- `resolve_ref(base_path, ref_path)` 可把声明文件中的相对引用一次性归一为 canonical 绝对路径（`/assets/...`）。
- Aseprite NPC 动画通过 `AnimationLoader` 在本包内做编译结果缓存（key 为规范化后的 `animations_path`），避免重复构图与注册资产。

## 接入示例

```moonbit nocheck
@resource.register_async_loader("mapx", my_map_loader)
@resource.register_async_loader("npc", my_npc_loader)

let map_loader = @resource.get_async_loader("mapx")
let raw = await map_loader.load_resource(["Map", "Map0", "100000000"])
let npc_loader = @resource.require_async_loader("npc")
let mx_path = "Npc/Npc/0002007.img/mx.json"
let mx = await npc_loader.load_data(mx_path)
let anim_path = @resource.resolve_ref(
  npc_loader.resolve_json_path(mx_path),
  "animation.json",
)
let image = npc_loader.load_image("Npc/Npc/0002007.img/animation.png")
ignore(mx)
ignore(image)
ignore(anim_path)
```

## NPC Aseprite 动画

```moonbit nocheck
let npc_loader = @resource.require_async_loader("npc")
let animation_loader = @resource.AnimationLoader::new(npc_loader)
let loaded = await animation_loader.load("Npc/Npc/0002007.img/animation.json")
let stand = loaded.clip("stand")
ignore(stand)
```
