# Local Server

A local server implementation for playing the game offline.

Although there is an open-source server implementation `Cosmic`,
it is burdensome to implement full client features, so this package provides an in-process local server.

## Persistence

The `LocalServer` constructor requires a `db` dependency:

```moonbit nocheck
///|
let server = LocalServer(db=@file_db.FileDB())
```

- Character snapshot data is persisted by local server through `save_character/load_character`.
- The storage backend contract is `DB` in this package.
- Native entrypoints construct `file_db.FileDB`.
- JS/WebGPU entrypoints construct `BrowserDB`.
- Client preference storage (UI layout/size etc.) should use a separate client-side DB package.

## Runtime Integration

```moonbit nocheck
///|
let server = LocalServer(db=@file_db.FileDB())

///|
let app = @game_app.base_app().add_plugin(@game_app.game_systems(server))
```

## Map Resource Contract

`local_server/transition` now resolves portal target data from exported map resources:

- read `MapX/<mapId>.img/mx.json`
- follow `tiled_path` to load `tiles/<mapId>.img.tmj`
- read `portal` object layer (`pn/tm/tn`) and compute `portal_id` by object order
