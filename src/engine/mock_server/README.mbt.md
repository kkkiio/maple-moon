# Mock Server

Stateful `GameServer` test double for black-box tests.

Each `MockServer` owns its sent client messages, registered server-message
handlers, and tick count. Tests explicitly install an instance through
`engine/game_server`, drive server messages with `emit`, and inspect only that
instance's recorded state.

```moonbit nocheck
let server = MockServer()
@game_server.install(server)
@game_server.init_server()
@game_server.send(request)
inspect(server.sent_count(request_type_code), content="1")
```
