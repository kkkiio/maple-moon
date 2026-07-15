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

`src/graphics_test/` package uses:

- `supported_targets = "native"`;
- `Milky2018/selene_raylib/*` platform overrides;
- `@capture_app.capture_after_frames` to run a hidden raylib context and capture
  the selected frame;
- `@capture_app.snapshot(path, png)` for PNG baseline comparison.

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

## Consequences

- Routine graphics tests run with `moon test --target native`.
- PNG updates use `UPDATE_GRAPHICS_SNAPS=true`.
- Inspect updates use `moon test --update`.
- Browser runtime validation stays in maple-cli and CDP checks.
- Selene's `test_graphics` package is not part of the Maple graphics snapshot
  path.
- Snapshot tests compare deterministic PNG files without `visual_desc`.

## Alternatives Considered

- Use browser WebGPU as the graphics snapshot backend.
  Rejected because graphics snapshots should run in `moon test` without a
  browser harness, Playwright, CDP coordination, or an HTTP snapshot endpoint.
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

Run all snapshot packages:

```bash
just test
```
