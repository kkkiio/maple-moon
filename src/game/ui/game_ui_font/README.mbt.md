# game_ui_font

`game_ui_font` defines the single typography role used by standard
player-facing game UI. It loads Fusion Pixel through the resource-pack VFS and
returns a Selene `TextFont` while preserving each widget's semantic size.

Display lettering rendered from existing MapleStory image resources and
developer tooling fonts stay outside this package.

```moonbit nocheck
let body = text_font()
let compact = text_font(size=11.0)
let emphasized = text_font(size=14.0, bold=true)
ignore(body)
ignore(compact)
ignore(emphasized)
```
