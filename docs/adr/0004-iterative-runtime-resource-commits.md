# ADR 0004: Iterative Runtime Resource Commits

Date: 2026-06-12

## Status

Accepted

## Context

Maple Moon resources are generated from large upstream MapleStory data sets.
Committing every exported image, spritesheet, map, NPC, quest, and item file
would make the repository hard to review and slow to clone.

At the same time, render snapshot tests and the current game runtime must be
fully reproducible from Git. Missing image files can otherwise render as
transparent output and hide real resource regressions.

## Decision

Keep broad generated resource roots ignored by default, including `assets/Map`,
`assets/images`, `assets/spritesheets/Map`, `assets/spritesheets/UI`,
`assets/Quest`, and `assets/Npc`.

When a test or runtime path needs resources from an ignored root, add the
smallest verified transitive closure with `git add --force`. A resource closure
includes the primary JSON data plus every referenced image, spritesheet,
tileset, animation JSON, packed PNG, and `.aseprite` source file needed to
recreate or review that runtime output.

Do not commit incomplete generated container JSON files whose referenced images
are not present. Either complete the export first or leave the local generated
file out of the change.

## Consequences

- Default tests and Web builds depend only on resource files committed to Git.
- Large raw/generated resource directories stay local unless a file is
  intentionally promoted into the runtime closure.
- Resource additions stay reviewable because ignored files must be force-added
  explicitly.
- Snapshot tests should fail on image-load errors instead of accepting
  transparent missing-resource output.
- Resource work must include dependency review, not just the top-level JSON
  file that triggered a failing load.

## Alternatives Considered

- Commit all generated resources.
  Rejected because the repository would become too large and noisy for normal
  development.
- Keep generated resources entirely local.
  Rejected because tests and builds would depend on untracked machine state.
- Fetch resources dynamically during tests.
  Rejected because it would add network and cache behavior to the deterministic
  snapshot path.
