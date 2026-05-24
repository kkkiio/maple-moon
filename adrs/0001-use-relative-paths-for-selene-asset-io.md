# ADR 0001: Use Relative Paths For Selene Asset IO

Date: 2026-05-24

## Status

Accepted

## Context

Maple Moon resources are consumed by native raylib, WebGPU tests, local file
loaders, and browser-style HTTP serving. The old `/assets/...` convention mixed
two unrelated meanings:

- In a browser, `/assets/foo.png` is a request path relative to the web server
  root.
- In a native raylib client, `/assets/foo.png` is an absolute filesystem path
  from the operating-system root directory.

The native game runs from the project root, where runtime assets live under the
relative directory `assets/`. Passing `/assets/...` directly to Selene asset APIs
therefore asks raylib to open files under the filesystem root and fails even
though `assets/...` exists in the working directory.

Silently stripping the leading slash makes this ambiguity harder to see. It can
also hide bugs where a Web URL path, a native filesystem path, and a logical
resource path are accidentally treated as the same string.

Bevy commonly uses paths relative to its asset root. Godot uses an explicit
scheme such as `res://`. Both avoid using a bare leading slash as the resource
root marker.

## Decision

Use `assets/...` as Maple Moon's resolved asset path format.

Do not treat `/assets/...` as a valid logical path. Leading-slash paths must fail
at the resource resolver boundary instead of being stripped.

The resource package distinguishes three path contexts:

- source-relative input, such as `Consume/0200.img`, resolved by a named loader
  source;
- file-relative references, such as Aseprite `animation.png` or Tiled
  `../../tilesets/foo.tsj`, resolved against the declaring file;
- resolved asset paths, always in the form `assets/...`, and suitable for Selene
  asset IO, local file IO, and test HTTP serving.

Game code should use `AsyncLoader` and `resource` resolver APIs to move from
source-relative or file-relative paths to resolved `assets/...` paths before
calling Selene asset APIs.

## Consequences

- Selene does not need Maple Moon-specific `/assets` behavior.
- Native raylib can read assets from the project working directory.
- WebGPU tests continue to work because the test server serves `assets/` from
  the project root.
- Resource reference resolution can stay canonical and deterministic.
- Direct Selene asset calls in Maple Moon should only use already-resolved
  `assets/...` paths.
- Existing `/assets/...` inputs are breaking errors, not compatibility aliases.

## Alternatives Considered

- Modify `selene-raylib` to special-case `/assets/...`.
  Rejected because `/assets` is an application convention, not an engine
  convention.
- Keep `/assets/...` and strip it at IO boundaries.
  Rejected because it preserves the Web/native ambiguity and makes invalid paths
  look valid.
- Introduce a new `AssetPath` or `res://` type immediately.
  Deferred because the current migration can be completed with strict string
  semantics. A typed path can be designed later once the resolved path model is
  stable.
