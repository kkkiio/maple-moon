# `ms/animation`

统一动画运行时门面。

- 输入：`resource` 层的 `NxAnimation` / `NxTexture` 描述。
- 输出：可直接挂到实体的 sprite 与播放控制 API。
- 后端：
  - `Native`：单图源 + 固定 origin + 固定尺寸，走 Selene `TextureAtlas + AnimationClip/Graph/Player`。
  - `Scripted`：逐帧 pivot/多图源/变尺寸，走 `ms/animation` 自有系统。

## 主要 API

- `from_nx_animation`
- `from_nx_texture`
- `sprite_from_animation`
- `sprite_from_picture`
- `play_animation`
- `set_animation_transform`
- `set_animation_speed`
- `is_animation_finished`
- `stop_animation`
- `animation_system`
