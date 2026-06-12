# Game Server

Virtual package facade for client-to-server messages.

The default implementation is a no-op fallback. The game executable overrides
this package with `lib/local_server/local_server_workaround`, which hosts
`local_server` in process. Tests may override it with `tests/mock_server`.

## Usage

```moonbit nocheck
@game_server.init_server()
@game_server.server_system(1.0 / 60.0)
```
