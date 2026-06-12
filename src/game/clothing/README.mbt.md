# `lib/ms/clothing`

This package parses character equipment resources into render-ready clothing animations.

## Responsibilities

- Parse equipment item resources (`ItemData.src`) into per-stance/per-part frame data.
- Map resource `z` tags to `ClothingLayer` for runtime z-order control.
- Align equipment textures to body draw anchors by stance/frame.

## Weapon Structured Parsing

- `NxWeapon`: structured weapon resource parsed from JSON.
- `NxWeaponAction`: frame table for one weapon action (`shoot2`, `stand1`, etc.).
- `NxWeaponFrame`: renderable parts in a specific frame.
- `NxWeaponPart`: texture + `z` + `map` anchor for one part.
- `NxMapAnchor`: parsed `map` anchor (`parent_key`, `parent_pos`).

Weapon parsing is strict: missing required fields (`map`, `origin`, `z`) fails early.

## Reusable Anchor Rule

- `resolve_anchor_shift(drawinfo, stance, frame, parent_key, parent_pos)` returns:
  `base_anchor_position - parent_pos`
- Supported anchor keys:
  - `handMove` -> hand position
  - `hand` -> arm position
  - `navel` -> body position
