# `ms/animation`

统一动画运行时门面（单一 Selene 后端）。

- 输入：`resource` 层的 `NxAnimation` / `NxTexture`，以及已编译的 `SeleneClip`。
- 输出：可直接挂到实体的 sprite 与播放控制 API。
- 后端：仅 Selene `TextureAtlas + AnimationClip/Graph/Player`。

## 主要 API

- `from_nx_animation`
- `from_selene_clip`
- `from_nx_texture`
- `sprite_from_animation`
- `sprite_from_picture`
- `play_animation`
- `set_animation_transform`
- `set_animation_speed`
- `is_animation_finished`
- `stop_animation`
