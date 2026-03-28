# Resource

定义资源 loader 接口与运行时 loader 注册表。上层 package（例如 `apps/game`）负责安装具体 loader。

约束：

- 本包不做业务缓存。
- 业务缓存放在调用方（例如 `skill`、`quest_icon`）。

## 接入示例

```moonbit nocheck
@resource.register_async_loader("mapx", my_map_loader)
@resource.register_async_loader("npc", my_npc_loader)

let map_loader = @resource.get_async_loader("mapx")
let raw = await map_loader.load_resource(["Map", "Map0", "100000000"])
```
