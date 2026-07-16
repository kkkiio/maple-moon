# vfx_afterimage

After-image VFX runtime and exported resource loading.

- Loads `res://Character/Afterimage/<name>.img/mx.json` bundles that reference
  Aseprite `animation.json`/`animation.png` tags.
- Keeps legacy NX after-image JSON parsing for skill data that still embeds the
  old shape.
- Manages per-entity after-image instances and lifecycle.
- Uses `character_presentation.CharLook` as the frame source in runtime API.
