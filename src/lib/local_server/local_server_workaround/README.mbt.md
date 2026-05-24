# Local Server Workaround

This package implements `KKKIIO/maple-moon/lib/game_server` by bridging it to
the in-process `local_server`.

It is intentionally separate from `game_server` so the virtual interface can
stay implementation-free. JS builds use `BrowserDB`; native builds use
`FileDB`.

```moonbit nocheck
@game_server.init_server()
@game_server.server_system(1.0 / 60.0)
```
