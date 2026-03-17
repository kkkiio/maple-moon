# Local Server

A local server implementation for playing the game offline.

Although there is an open-source server implementation `Cosmic`,
it is burdensome to implement full client features, so this package provides an in-process local server.

## Persistence

`LocalServer::new` requires a `db` dependency:

```moonbit nocheck
let server = @local_server.LocalServer::new(db=@local_server.BrowserDB::new())
```

- Character snapshot data is persisted by local server through `save_character/load_character`.
- The storage backend contract is `DB` in this package.
- Client preference storage (UI layout/size etc.) should use a separate client-side DB package.

## Runtime Integration

```moonbit nocheck
let server = @local_server.LocalServer::new(db=@local_server.BrowserDB::new())
@local_server.init_server(server)

@system.App::new()
.add_system(delta => @local_server.server_system(server), system_name="local_server_system")
```
