# Local Server

A local server implementation for playing the game offline.

Although there is an open-source server implementation `Cosmic`,
it is burdensome to implement full client features, so this package provides an in-process local server.

## Persistence

`LocalServer::new` requires a `db` dependency:

```moonbit nocheck
///|
let server = @local_server.LocalServer::new(db=@local_server.FileDB::new())
```

- Character snapshot data is persisted by local server through `save_character/load_character`.
- The storage backend contract is `DB` in this package.
- Native builds use `FileDB`; JS/WebGPU builds use `BrowserDB` through the `local_server_workaround` bridge package.
- Client preference storage (UI layout/size etc.) should use a separate client-side DB package.

## Runtime Integration

```moonbit nocheck
let server = @local_server.LocalServer::new(db=@local_server.FileDB::new())
@local_server.init_server(server)

@system.App::new()
.add_system(delta => @local_server.server_system(server), system_name="local_server_system")
```

## Map Resource Contract

`local_server/transition` now resolves portal target data from exported map resources:

- read `MapX/<mapId>.img/mx.json`
- follow `tiled_path` to load `tiles/<mapId>.img.tmj`
- read `portal` object layer (`pn/tm/tn`) and compute `portal_id` by object order
