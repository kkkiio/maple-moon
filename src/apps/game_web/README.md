# apps/game_web

Maple Moon web entry package.

This main package selects the Selene WebGPU backend and delegates the shared
runtime setup to `KKKIIO/maple-moon/lib/game_app`. Use this entry for fast local
verification, browser debugging, and the Vite development page.

## Usage

```bash
moon build --target js --release src/apps/game_web
```
