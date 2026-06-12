# ADR 0003: Use Target-Specific Game Entrypoints

Date: 2026-06-12

## Status

Accepted

## Context

Maple Moon uses Selene with two practical backend needs:

- WebGPU/JS is faster for daily verification, works well with browser developer
  tools, and is already the render snapshot path.
- raylib/native is the intended player-facing runtime for local play and
  distribution.

The old `apps/game` package combined shared game wiring with the native backend
override. That made the package look like the only game entrypoint even though
the project already relied on WebGPU for visual verification.

MoonBit 0.10 also warns when main packages contain blackbox-only inputs such as
`README.mbt.md`. Moving shared behavior into a non-main package keeps checked
package docs where they are useful and leaves main packages as small backend
selectors.

## Decision

Use one shared runtime package plus two target-specific app packages:

- `src/engine/game_app` owns shared resource setup, local-server handler
  registration, game-state initialization, and Selene system registration.
- `src/apps/game_web` is the JS/WebGPU main package used for fast verification,
  browser debugging, and the Vite development page.
- `src/apps/game_native` is the native/raylib main package used for local play
  and player-facing distribution builds.

Main packages use `README.md`. Non-main packages continue to use
`README.mbt.md` so documentation examples remain checked by MoonBit.

## Consequences

- Game system wiring is maintained in one place.
- Web verification can run through the same shared app setup as native play.
- CI and local checks must cover both JS and native targets with `moon check`.
- Routine tests run the WebGPU snapshot runner. It builds selected tests with
  `moon test --target js --build-only`, then executes them in a browser
  environment with the required asset server.
- Routine builds build only `src/apps/game_web`.
- Native release builds are explicit and only run when preparing local play or
  player-facing distribution.
- Web verification does not replace native build verification before native
  distribution.
- Backend-specific package overrides stay isolated in thin app packages.

## Development Workflow

Use these commands for daily development:

```bash
just check
just test
just build
```

Use this command only when a native player build is needed:

```bash
just build-native
```

Do not use bare `moon test` as the normal project test command. It generates
native test executables for native-capable packages, including generated
blackbox drivers for packages without hand-written tests, and therefore pulls
raylib/native C compilation and linking into the feedback loop.

Do not use full-repository `moon test --target js` as the normal project test
command either. Render tests depend on browser APIs and the asset server in
`scripts/moon-webgpu-test.mjs`; running those artifacts directly under Node.js
turns the environment boundary into unrelated resource failures.

## Alternatives Considered

- Keep a single native `apps/game` entrypoint.
  Rejected because it hides the WebGPU validation workflow and keeps backend
  selection coupled to shared runtime setup.
- Use only a web entrypoint.
  Rejected because native remains the player-facing runtime.
- Duplicate full app wiring in both entrypoints.
  Rejected because shared systems would drift and require duplicate updates.
