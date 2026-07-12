# Scoped Runtime Resource Commits

Date: 2026-06-12

## Context

Maple Moon resources are generated from large upstream MapleStory data sets.
Committing every exported image, spritesheet, map, NPC, quest, skill, UI, and
item file would make the repository hard to review and slow to clone.

At the same time, render snapshot tests and the current game runtime must be
fully reproducible from Git. Missing image files can otherwise render as
transparent output and hide real resource regressions.

The original NX-derived resource workspace lives outside this repository in
`../nx_maple_res`, so generated artifacts that are useful only as local
intermediate output can be deleted and regenerated.

## Decision

Do not ignore broad `assets/` roots in `.gitignore`. Make generated resources
visible to Git so `git status` exposes local resource drift.

Promote resources into Git by scope. For the current project scope, commit
Victoria Island maps, the maps' NPC and monster closures, required BGM/SFX, and
the minimal UI resources that runtime code or tests actually load.

A resource closure includes the primary JSON data plus every referenced Tiled
map, tileset, image, spritesheet, animation JSON, packed PNG, audio file, and
`.aseprite` source file needed to recreate or review that runtime output.

Do not commit incomplete generated container JSON files whose referenced images
are not present. Either complete the export first, keep the local generated file
out of the change, or delete the local intermediate file and regenerate it from
`../nx_maple_res` when needed.

Treat ordinary monster drop clutter, full UI dumps, unconnected skill bundles,
and old extracted bitmap pools as local candidates until design or runtime code
uses them.

## Consequences

- Default tests and Web builds depend only on resource files committed to Git.
- Large raw/generated resource directories show up in `git status`, which makes
  cleanup explicit instead of hiding drift behind ignore rules.
- Resource additions stay reviewable because commits are scoped by current
  design and runtime closure.
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
- Ignore broad generated roots and force-add selected files.
  Rejected because hidden drift made it harder to see which exported resources
  still needed review or deletion.
