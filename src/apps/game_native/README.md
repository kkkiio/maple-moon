# apps/game_native

Maple Moon native entry package.

This main package selects the Selene raylib backend and delegates the shared
runtime setup to `KKKIIO/maple-moon/lib/game_app`. Use this entry for local
native play and player-facing distribution builds.

## Usage

```bash
moon run --target native --release src/apps/game_native
```
