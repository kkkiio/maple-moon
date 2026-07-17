# Use Native Raylib For Graphics Snapshots

## Context

Maple Moon has browser and native runtime entrypoints. Browser checks are useful
for JS runtime errors, failed network requests, and CDP-driven playtest flows.
Graphics snapshot tests have a different job: produce deterministic PNG
baselines that are easy to update, review, and compare in `moon test`.

The snapshot path should avoid browser-only harnesses and project-specific
Selene APIs. It should exercise Selene's native raylib backend directly and keep
the test API close to the shared `App` runtime.

PNG snapshot updates cannot reliably reuse MoonBit's `moon test --update`
signal. MoonBit inspect snapshots and PNG snapshots therefore use separate
update switches.

## Decision

Graphics snapshot tests run on the native raylib backend.

Graphics snapshot tests are currently local-only and are excluded from the
GitHub Actions regression workflow. The native raylib path requires a working
OpenGL context: GitHub-hosted Apple Silicon runners expose Metal but cannot
provide the NSGL pixel format required by GLFW, while Linux Mesa produces
platform-specific pixels that do not match baselines captured on a local Apple
GPU. Intel macOS runners would change the renderer and architecture again, so
they do not provide an equivalent baseline environment.

`src/graphics_test/` package uses:

- `supported_targets = "native"`;
- `KKKIIO/selene_raylib/*` platform overrides;
- the repository `assets/base/` and `assets/dlc-victoria/` packs mounted in the same
  `res://` VFS used by the game;
- `@capture_app.capture_after_frames` to run a hidden raylib context and capture
  the selected frame;
- `@capture_app.snapshot(path, png)` for PNG baseline comparison.

The graphics test package initializes `src/engine/res` before loading JSON,
images, audio, or fonts. Tests refer to runtime resources with `res://` paths;
`@res` resolves them to physical paths within the mounted packs, and Selene
loads and decodes from those paths.

`@capture_app.capture_after_frames` delegates frame execution and screenshot
selection to `App::run_frames_capture`. Maple tests pass
`capture_frame_indexes=Some([frames - 1])` so long-running tests only return the
target frame instead of producing one PNG per rendered frame.

`@capture_app.snapshot` writes PNG baselines only when
`UPDATE_GRAPHICS_SNAPS=true` or the snapshot file is missing. `moon test
--update` is reserved for `debug_inspect` / `json_inspect` baselines.

Each graphics test must run data snapshots before pixel snapshots:

```moonbit
@debug.debug_inspect({ "entity_count": @entity.iter_entities().to_array().length() })
let capture = @capture_app.capture_after_frames(app, 60, width=800, height=600)
@capture_app.snapshot("src/graphics_test/__snapshot__/feature/scene.png", capture.png)
```

Tests that load raylib textures before `capture_after_frames` must call
`@capture_app.ensure_native_context(width=..., height=...)` first.

Pure data and gameplay tests do not inherit the graphics package overrides.
They construct resource values directly. Resolver and loader tests replace
Selene's virtual platform reader with an in-memory map of physical paths, then
exercise the same ordered directory mounts used by production.

## Consequences

- Routine graphics tests run with `moon test --target native`.
- `just test` runs the fast non-graphics native test suite; use
  `just test-graphics` explicitly for graphics snapshots.
- GitHub Actions runs `just test` and does not install a display server or
  native graphics dependencies.
- PNG updates use `UPDATE_GRAPHICS_SNAPS=true`.
- Inspect updates use `moon test --update`.
- Browser runtime validation stays in maple-cli and CDP checks.
- Selene's `test_graphics` package is not part of the Maple graphics snapshot
  path.
- Snapshot tests compare deterministic PNG files without `visual_desc`.
- Missing resource keys and invalid `res://` paths fail before pixel comparison;
  transparent output is not accepted as a resource-load result.

## Alternatives Considered

- Use browser WebGPU as the graphics snapshot backend.
  Rejected because graphics snapshots should run in `moon test` without a
  browser harness, Playwright, CDP coordination, or an HTTP snapshot endpoint.
  WebGPU capture also requires a real browser WebGPU environment and asynchronous
  adapter, device, submission, and readback coordination that `moon test --target js`
  does not provide.
  Browser runtime health is covered by maple-cli instead.

- Keep a Maple-specific graphics test package in Selene.
  Rejected because frame execution and frame selection belong in the generic
  `App::run_frames_capture` API, while Maple-specific snapshot comparison and
  mock server bridge code belong in Maple Moon.

- Capture every rendered frame and select the target PNG in Maple Moon.
  Rejected because long-running tests can render hundreds of frames; selecting
  frames inside `App::run_frames_capture` avoids producing unused PNG artifacts.

- Reuse `moon test --update` for PNG snapshots.
  Rejected because test code cannot reliably read MoonBit's update signal. PNG
  updates use `UPDATE_GRAPHICS_SNAPS=true`; `--update` remains dedicated to
  inspect snapshots.

- Keep `visual_desc` on PNG snapshots.
  Rejected because snapshot path and test name already explain the expected
  image, and free-form visual descriptions invite self-confirming assertions.

## Revisit Conditions

Re-enable graphics snapshots in GitHub Actions after Selene has a deterministic
capture backend that does not depend on the hosted runner's legacy OpenGL
support. Evaluate these directions against the existing snapshot suite:

- Add or adopt a native Selene backend built on a modern cross-platform GPU
  abstraction with first-class Metal support. This must preserve strict frame
  selection and provide deterministic asynchronous readback without requiring a
  browser harness.
- Compile raylib 6 with `rlsw` and `PLATFORM_MEMORY` for CPU-only headless
  rendering. This must support the render textures, blending, fonts, and shader
  behavior used by Maple Moon before its output can become the canonical CI
  baseline.

Choose the backend based on rendering compatibility and snapshot determinism;
do not use pixel tolerance to compensate for different platform renderers.

## Commands

Run one package:

```bash
MOONBIT_NEW_NATIVE=1 moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```

Update PNG baselines:

```bash
MOONBIT_NEW_NATIVE=1 UPDATE_GRAPHICS_SNAPS=true moon test --target native --deny-warn --diagnostic-limit 200 src/graphics_test
```

Update inspect baselines:

```bash
MOONBIT_NEW_NATIVE=1 moon test --target native --update --deny-warn --diagnostic-limit 200 src/graphics_test
```

Run the fast non-graphics test suite:

```bash
just test
```

Run graphics snapshots explicitly:

```bash
just test-graphics
```
