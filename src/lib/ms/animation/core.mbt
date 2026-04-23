///|
using @resource {type NxTexture, type NxAnimation, type SeleneClip}

///|
pub(all) struct PictureSpec {
  image : @asset.ImageHandle
  rect : @math.Rect
  size : @math.Vec2
  origin : @math.Vec2
  repeat : @math.RepeatMode
  flip_x : Bool
}

///|
pub(all) struct Picture {
  spec : PictureSpec
}

///|
pub(all) struct AnimationFrame {
  image : @asset.ImageHandle
  size : @math.Vec2
  offset : @math.Vec2
  pivot : @math.Vec2
  duration : Double
}

///|
pub(all) struct Animation {
  clip : SeleneClip
  loop_ : Bool
}

///|
pub fn nx_texture_to_picture_spec(
  texture : NxTexture,
  size? : @math.Vec2,
  repeat? : @math.RepeatMode = NoRepeat,
  flip_x? : Bool = false,
) -> PictureSpec {
  guard repeat is NoRepeat || texture.offset is { x: 0, y: 0 } else {
    abort("tiled texture in spritesheet is not supported")
  }
  let resolved_size : @math.Vec2 = size.unwrap_or(
    @math.Vec2(texture.w.to_double(), texture.h.to_double()),
  )
  let rect : @math.Rect = {
    position: @math.Vec2(
      texture.offset.x.to_double(),
      texture.offset.y.to_double(),
    ),
    size: @math.Vec2(texture.w.to_double(), texture.h.to_double()),
  }
  {
    image: @asset.load_image(texture.i),
    rect,
    size: resolved_size,
    origin: @math.Vec2(
      texture.origin.x.to_double(),
      texture.origin.y.to_double(),
    ),
    repeat,
    flip_x,
  }
}

///|
pub fn Animation::new(
  frames : Array[AnimationFrame],
  loop_? : Bool = true,
) -> Animation {
  guard !frames.is_empty() else { abort("animation frames must not be empty") }
  let clip = compile_frames_to_selene_clip(frames, "ms/animation/manual")
  { clip, loop_ }
}

///|
pub fn Animation::single_frame(
  path : String,
  size : @math.Vec2,
  offset? : @math.Vec2 = @math.Vec2::zero(),
  pivot? : @math.Vec2 = @math.Vec2::zero(),
  duration? : Double = 1.0,
) -> Animation {
  Animation::new([
    { image: @asset.load_image(path), size, offset, pivot, duration },
  ])
}

///|
pub fn Animation::single_frame_from_image(
  image : @asset.ImageHandle,
  size : @math.Vec2,
  offset? : @math.Vec2 = @math.Vec2::zero(),
  pivot? : @math.Vec2 = @math.Vec2::zero(),
  duration? : Double = 1.0,
) -> Animation {
  Animation::new([{ image, size, offset, pivot, duration }])
}

///|
pub fn from_nx_texture(
  texture : NxTexture,
  size? : @math.Vec2,
  repeat? : @math.RepeatMode = NoRepeat,
  flip_x? : Bool = false,
) -> Picture {
  let spec = match size {
    Some(v) => nx_texture_to_picture_spec(texture, size=v, repeat~, flip_x~)
    None => nx_texture_to_picture_spec(texture, repeat~, flip_x~)
  }
  { spec, }
}

///|
pub fn from_nx_animation(src : NxAnimation, loop_? : Bool = false) -> Animation {
  let frames : Array[AnimationFrame] = []
  for frame in src.frames {
    let texture = frame.texture
    let delay_ms = match frame.delay {
      Some(d) => if d <= 0 { 100 } else { d }
      None => 100
    }
    frames.push({
      image: @asset.load_image(texture.i),
      size: @math.Vec2(texture.w.to_double(), texture.h.to_double()),
      offset: @math.Vec2(
        texture.offset.x.to_double(),
        texture.offset.y.to_double(),
      ),
      pivot: @math.Vec2(
        texture.origin.x.to_double(),
        texture.origin.y.to_double(),
      ),
      duration: delay_ms.to_double() / 1000.0,
    })
  }
  let effective_frames = if src.zigzag && frames.length() > 2 {
    let expanded = frames.copy()
    for i = frames.length() - 2; i >= 1; i = i - 1 {
      expanded.push(frames[i])
    }
    expanded
  } else {
    frames
  }
  guard !effective_frames.is_empty() else {
    abort("nx animation frames must not be empty")
  }
  let clip = compile_frames_to_selene_clip(effective_frames, "ms/animation/nx")
  { clip, loop_ }
}

///|
/// Build an animation from one compiled Selene clip.
pub fn from_selene_clip(clip : SeleneClip, loop_? : Bool = true) -> Animation {
  { clip, loop_ }
}

///|
pub fn animation_dimensions(animation : Animation) -> @math.Vec2 {
  @math.Vec2(
    animation.clip.dimensions.x.to_double(),
    animation.clip.dimensions.y.to_double(),
  )
}

///|
pub fn sprite_from_picture(
  picture : Picture,
  _z : Int,
  alpha? : Double = 1.0,
) -> @sprite.Sprite {
  let spec = picture.spec
  let flip_x = spec.flip_x
  @sprite.Sprite::new(
    image=Some(spec.image),
    rect=Some(spec.rect),
    custom_size=Some(spec.size),
    anchor=anchor_from_origin(spec.origin, spec.size, flip_x~),
    flip_x~,
    image_mode=if spec.repeat is NoRepeat {
      @sprite.SpriteImageMode::Auto
    } else {
      @sprite.SpriteImageMode::Tiled(spec.repeat)
    },
    color=white_with_alpha(alpha),
  )
}

///|
pub fn sprite_from_animation(
  animation : Animation,
  _z : Int,
  transform? : @math.Transform = @math.Transform::identity(),
  alpha? : Double = 1.0,
) -> @sprite.Sprite {
  let flip_x = transform.a < 0.0
  let anchor = if flip_x {
    mirror_anchor_x(animation.clip.anchor)
  } else {
    animation.clip.anchor
  }
  @sprite.Sprite::new(
    image=Some(animation.clip.image),
    texture_atlas=Some(@sprite.TextureAtlas::new(animation.clip.layout)),
    anchor~,
    flip_x~,
    color=white_with_alpha(alpha),
  )
}

///|
pub fn play_animation(
  entity : @entity.Entity,
  animation : Animation,
  loop_? : Bool = animation.loop_,
  transform? : @math.Transform = @math.Transform::identity(),
) -> Unit {
  set_animation_transform(entity, transform)
  @selene_animation.animation_target_ids().set(
    entity,
    @selene_animation.AnimationTargetId::new("self"),
  )
  @selene_animation.animated_bys().set(
    entity,
    @selene_animation.AnimatedBy::new(entity),
  )
  @selene_animation.animation_graph_handles().set(entity, animation.clip.graph)
  let player = @selene_animation.animation_players().get_or_init(entity, fn() {
    @selene_animation.AnimationPlayer::new()
  })
  let repeat = if loop_ {
    @selene_animation.RepeatAnimation::Forever
  } else {
    @selene_animation.RepeatAnimation::Never
  }
  ignore(player.play(animation.clip.node, repeat~))

  let anchor = if transform.a < 0.0 {
    mirror_anchor_x(animation.clip.anchor)
  } else {
    animation.clip.anchor
  }
  match @sprite.sprites().get(entity) {
    Some(sprite) =>
      @sprite.sprites().set(entity, {
        ..sprite,
        image: Some(animation.clip.image),
        texture_atlas: Some(@sprite.TextureAtlas::new(animation.clip.layout)),
        anchor,
      })
    None =>
      @sprite.sprites().set(
        entity,
        @sprite.Sprite::new(
          image=Some(animation.clip.image),
          texture_atlas=Some(@sprite.TextureAtlas::new(animation.clip.layout)),
          anchor~,
          flip_x=transform.a < 0.0,
        ),
      )
  }
}

///|
pub fn set_animation_transform(
  entity : @entity.Entity,
  transform : @math.Transform,
) -> Unit {
  if @sprite.sprites().get(entity) is Some(sprite) {
    let flip_x = transform.a < 0.0
    let anchor = if sprite.flip_x != flip_x {
      mirror_anchor_x(sprite.anchor)
    } else {
      sprite.anchor
    }
    @sprite.sprites().set(entity, { ..sprite, flip_x, anchor })
  }
  match @transform.transforms().get(entity) {
    Some(t) =>
      @transform.transforms().set(entity, {
        ..t,
        translation: @math.Vec3::new(
          transform.tx,
          transform.ty,
          t.translation.z,
        ),
      })
    None => @transform2d.set_xy(entity, @math.Vec2(transform.tx, transform.ty))
  }
}

///|
pub fn set_animation_speed(entity : @entity.Entity, speed : Double) -> Unit {
  let safe = if speed < 0.0 { 0.0 } else { speed }
  if @selene_animation.animation_players().get(entity) is Some(player) {
    for _, pair in player.playing_animations() {
      let (_, active) = pair
      ignore(active.set_speed(safe))
    }
  }
}

///|
pub fn is_animation_finished(entity : @entity.Entity) -> Bool {
  match @selene_animation.animation_players().get(entity) {
    Some(player) => player.all_finished()
    None => true
  }
}

///|
pub fn stop_animation(entity : @entity.Entity) -> Unit {
  if @selene_animation.animation_players().get(entity) is Some(player) {
    ignore(player.stop_all())
  }
}

///|
fn compile_frames_to_selene_clip(
  frames : Array[AnimationFrame],
  clip_name : String,
) -> SeleneClip {
  guard !frames.is_empty() else { abort("animation frames must not be empty") }
  let first = frames[0]
  guard first.size.0 > 0.0 && first.size.1 > 0.0 else {
    abort("animation frame size must be positive")
  }
  for frame in frames {
    if frame.image != first.image {
      abort("animation frames must share one image for selene atlas playback")
    }
    if frame.size != first.size {
      abort(
        "animation frames must share one frame size for selene atlas playback",
      )
    }
    if frame.pivot != first.pivot {
      abort("animation frames must share one pivot for selene anchor playback")
    }
  }

  let rects : Array[@math.Rect] = []
  let keys : Array[@selene_animation.ScalarKeyframe] = []
  let mut t = 0.0
  for idx, frame in frames {
    rects.push({ position: frame.offset, size: frame.size })
    keys.push({
      time: t,
      value: idx.to_double(),
      in_tangent: None,
      out_tangent: None,
    })
    let duration = if frame.duration <= 0.0 { 0.001 } else { frame.duration }
    t += duration
  }

  let layout = @sprite.register_texture_atlas_layout(
    @sprite.TextureAtlasLayout::new(first.size, rects),
  )
  let clip = @selene_animation.AnimationClip::new(clip_name)
  clip.add_curve_to_target(
    @selene_animation.AnimationTargetId::new("self"),
    @selene_animation.VariableCurve::scalar(
      @selene_animation.texture_atlas_index_field(),
      keys,
      interpolation=@selene_animation.ChannelInterpolation::Step,
    ),
  )
  clip.duration = if t <= 0.0 { 0.001 } else { t }
  let clip_handle = @selene_animation.register_animation_clip_asset(clip)
  let (graph, nodes) = @selene_animation.AnimationGraph::from_clips([
    clip_handle,
  ])
  let graph_handle = @selene_animation.register_animation_graph_asset(graph)
  {
    image: first.image,
    layout,
    graph: graph_handle,
    node: nodes[0],
    anchor: anchor_from_origin(first.pivot, first.size),
    duration_ms: (clip.duration * 1000.0).to_int(),
    dimensions: @struct.Point::new(first.size.0.to_int(), first.size.1.to_int()),
  }
}

///|
fn anchor_from_origin(
  origin : @math.Vec2,
  size : @math.Vec2,
  flip_x? : Bool = false,
) -> @sprite.Anchor {
  let w = if size.0 <= 0.0 { 1.0 } else { size.0 }
  let h = if size.1 <= 0.0 { 1.0 } else { size.1 }
  let x = origin.0 / w - 0.5
  @sprite.Anchor(@math.Vec2(if flip_x { -x } else { x }, 0.5 - origin.1 / h))
}

///|
fn mirror_anchor_x(anchor : @sprite.Anchor) -> @sprite.Anchor {
  let @sprite.Anchor(v) = anchor
  @sprite.Anchor(@math.Vec2(-v.0, v.1))
}

///|
fn clamp_alpha(alpha : Double) -> Double {
  if alpha < 0.0 {
    0.0
  } else if alpha > 1.0 {
    1.0
  } else {
    alpha
  }
}

///|
fn white_with_alpha(alpha : Double) -> @selene_render.Color {
  let base = @sprite.color_from_css("white")
  { ..base, a: clamp_alpha(alpha) }
}
