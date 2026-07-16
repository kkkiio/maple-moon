# `lib/game_app`

Shared Maple Moon game runtime package.

This package wires resources, game-state transitions, server handlers, and
runtime systems into a Selene `App`. Platform-specific main packages construct
the `GameServer` passed to `game_systems` and select the rendering backend:

- `apps/game_web` uses the WebGPU backend for browser runtime checks and
  debugging, and registers the JS-only console plugin.
- `apps/game_native` uses the raylib backend for native play and distribution.

## Usage

```bash
moon run --target native --release src/apps/game_native
moon build --target js --release src/apps/game_web
```
