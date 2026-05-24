# `apps/game`

Maple Moon game entry package.

This package wires resources, game-state transitions, local-server handlers, and
runtime systems into a Selene `App`. It is the single native game entry package
and uses the raylib backend. Render snapshot tests are separate JS test packages
that select the WebGPU backend through their own test-only overrides.

## Usage

```bash
moon run KKKIIO/maple-moon/apps/game --target native
```
