# `lib/game_app`

Shared Maple Moon game runtime package.

This package wires resources, game-state transitions, local-server handlers, and
runtime systems into a Selene `App`. Platform-specific main packages select the
actual backend:

- `apps/game_web` uses the WebGPU backend for fast verification and browser
  debugging.
- `apps/game_native` uses the raylib backend for native play and distribution.

## Usage

```bash
moon run --target native --release src/apps/game_native
moon build --target js --release src/apps/game_web
```
