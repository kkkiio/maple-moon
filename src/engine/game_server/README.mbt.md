# Game Server

Runtime-configurable facade for client-to-server messages.

Game code calls the package-level `send`, handler-registration, and tick APIs.
Application entrypoints install one `GameServer` implementation before startup.
The browser and native games install `LocalServer`; black-box tests can install
an isolated `MockServer`.

## Usage

```moonbit nocheck
@game_server.install(server)
@game_server.init_server()
@game_server.send(message)
@game_server.server_system(1.0 / 60.0)
```
