# ADR 0002: Use WebGPU Headless Chrome For Render Snapshots

Date: 2026-05-24

## Status

Accepted

## Context

Maple Moon supports a native raylib backend for the game client and a WebGPU
backend for browser rendering. Render snapshot tests need to be fast enough for
regular development, deterministic enough for pixel comparison, and close enough
to the production rendering path to catch visual regressions.

Native raylib snapshot tests are possible, but repeatedly compiling and linking
native test executables is slower than running JS tests. Node.js is not a good
primary WebGPU host for these tests: the standard Node.js runtime does not expose
the browser `navigator.gpu` API by default, and the Node.js issue requesting this
was closed as not planned:
https://github.com/nodejs/node/issues/42896

The test code also depends on browser-like behavior around canvas, image loading,
and WebGPU runtime initialization. Recreating those browser APIs in Node would
turn the test harness into another rendering platform.

## Decision

Use `selene_webgpu` as the render snapshot backend and run the generated JS test
artifacts in Headless Chrome.

Keep the game executable as a single native raylib main. WebGPU is used for
render snapshot tests, not as a second production main entrypoint.

The test wrapper should:

- build selected MoonBit tests for the JS target,
- serve the generated test artifact and `assets/` over HTTP,
- launch Headless Chrome with WebGPU enabled,
- run the MoonBit test driver in the page,
- compare PNG bytes through the snapshot endpoint.

## Consequences

- Render snapshot tests avoid repeated native linking cost.
- Tests exercise the real browser WebGPU stack instead of a Node shim.
- The command can stay simple through `npm run test:webgpu`.
- A local Chrome installation is required for render snapshot tests.
- Native raylib still needs separate compile/link verification because snapshot
  tests intentionally use WebGPU for speed.

## Alternatives Considered

- Run WebGPU tests directly in Node.js.
  Rejected because standard Node.js does not provide the browser WebGPU/canvas
  environment these tests need.
- Use native raylib for all render snapshots.
  Rejected for the default test loop because compile/link cost is too high for
  frequent snapshot runs.
- Maintain separate backend-specific render snapshots.
  Rejected for now because it doubles snapshot churn and makes routine visual
  tests slower. Backend-specific snapshots can be added later for targeted
  raylib regressions.
