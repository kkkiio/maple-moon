# character_presentation

Character visual presentation runtime.

- Owns local stance/frame playback and part assembly for body/hair/face/equips.
- `char_look_system` now advances local animation states first, then applies dynamic layer sync.
- Exposes look module loading and runtime character look operations.
- Consumes `@character_body` draw info and body resource types.
