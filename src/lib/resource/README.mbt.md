# Resource

定义资源 loader 接口与运行时 loader 注册表。上层 package（例如 `apps/game`）负责安装具体 loader。

约束：

- 通用树形资源（`AsyncLoader::load_resource`）不做业务缓存。
- Aseprite NPC 动画通过 `AnimationLoader` 在本包内做编译结果缓存（key 为规范化后的 `animations_path`），避免重复构图与注册资产。

## 接入示例

```moonbit nocheck
@resource.register_async_loader("mapx", my_map_loader)
@resource.register_async_loader("npc", my_npc_loader)

let map_loader = @resource.get_async_loader("mapx")
let raw = await map_loader.load_resource(["Map", "Map0", "100000000"])
```

## NPC Aseprite 动画

```moonbit nocheck
let npc_loader = @resource.require_async_loader("npc")
let animation_loader = @resource.AnimationLoader::new(npc_loader)
let loaded = await animation_loader.load("Npc/Npc/0002007.img/animation.json")
let stand = loaded.clip("stand")
ignore(stand)
```
