///|
using @resource {type NxTexture, type NxAnimation}

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
pub(all) struct AnimationStep {
  image : @asset.ImageHandle
  rect : @math.Rect
  size : @math.Vec2
  origin : @math.Vec2
  duration : Double
}

///|
pub(all) struct AnimationPlayable {
  steps : Array[AnimationStep]
  loop_ : Bool
  native_eligible : Bool
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
pub fn nx_animation_to_playable(
  src : NxAnimation,
  loop_? : Bool = false,
) -> AnimationPlayable {
  let steps : Array[AnimationStep] = []
  for frame in src.frames {
    let delay_ms = match frame.delay {
      Some(d) => if d <= 0 { 100 } else { d }
      None => 100
    }
    let texture = frame.texture
    steps.push({
      image: @asset.load_image(texture.i),
      rect: {
        position: @math.Vec2(
          texture.offset.x.to_double(),
          texture.offset.y.to_double(),
        ),
        size: @math.Vec2(texture.w.to_double(), texture.h.to_double()),
      },
      size: @math.Vec2(texture.w.to_double(), texture.h.to_double()),
      origin: @math.Vec2(
        texture.origin.x.to_double(),
        texture.origin.y.to_double(),
      ),
      duration: delay_ms.to_double() / 1000.0,
    })
  }
  let effective_steps = if src.zigzag && steps.length() > 2 {
    let expanded = steps.copy()
    for i = steps.length() - 2; i >= 1; i = i - 1 {
      expanded.push(steps[i])
    }
    expanded
  } else {
    steps
  }
  {
    steps: effective_steps,
    loop_,
    native_eligible: is_native_eligible(effective_steps),
  }
}

///|
fn is_native_eligible(steps : Array[AnimationStep]) -> Bool {
  guard steps.length() > 0 else { return false }
  let first = steps[0]
  for step in steps {
    if step.image != first.image {
      return false
    }
    if step.size != first.size {
      return false
    }
    if step.origin != first.origin {
      return false
    }
  }
  true
}

///|
pub(all) struct Picture {
  spec : PictureSpec
}

///|
pub(all) struct NativeBackend {
  image : @asset.ImageHandle
  layout : @sprite.TextureAtlasLayoutHandle
  graph : @selene_animation.AnimationGraphHandle
  node : @selene_animation.AnimationNodeIndex
  anchor : @sprite.Anchor
}

///|
pub(all) enum AnimationBackend {
  Native(NativeBackend)
  Scripted
}

///|
pub(all) struct Animation {
  playback : AnimationPlayable
  backend : AnimationBackend
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
priv struct ScriptedState {
  animation : Animation
  mut step_index : Int
  mut step_elapsed : Double
  mut speed : Double
  mut finished : Bool
}

///|
let scripted_states : Map[@entity.Entity, ScriptedState] = Map::new()

///|
pub fn Animation::new(
  frames : Array[AnimationFrame],
  loop_? : Bool = true,
) -> Animation {
  let steps : Array[AnimationStep] = frames.map(fn(frame) {
    {
      image: frame.image,
      rect: { position: frame.offset, size: frame.size },
      size: frame.size,
      origin: frame.pivot,
      duration: if frame.duration <= 0.0 {
        0.001
      } else {
        frame.duration
      },
    }
  })
  let playback : AnimationPlayable = {
    steps,
    loop_,
    native_eligible: is_native_eligible_steps(steps),
  }
  { playback, backend: build_backend(playback) }
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
pub fn frame_count(animation : Animation) -> Int {
  animation.playback.steps.length()
}

///|
pub fn frame_size_at(animation : Animation, index : Int) -> @math.Vec2? {
  if index < 0 || index >= animation.playback.steps.length() {
    None
  } else {
    Some(animation.playback.steps[index].size)
  }
}

///|
pub fn frame_origin_at(animation : Animation, index : Int) -> @math.Vec2? {
  if index < 0 || index >= animation.playback.steps.length() {
    None
  } else {
    Some(animation.playback.steps[index].origin)
  }
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
  let playback = nx_animation_to_playable(src, loop_~)
  let backend = build_backend(playback)
  { playback, backend }
}

///|
fn build_backend(playback : AnimationPlayable) -> AnimationBackend {
  if !playback.native_eligible || playback.steps.is_empty() {
    return Scripted
  }
  let first = playback.steps[0]
  let rects : Array[@math.Rect] = []
  let keys : Array[@selene_animation.ScalarKeyframe] = []
  let mut t = 0.0
  for idx, step in playback.steps {
    rects.push(step.rect)
    keys.push({
      time: t,
      value: idx.to_double(),
      in_tangent: None,
      out_tangent: None,
    })
    t += step.duration
  }
  guard !keys.is_empty() else { return Scripted }
  let layout = @sprite.register_texture_atlas_layout(
    @sprite.TextureAtlasLayout::new(first.size, rects),
  )
  let clip = @selene_animation.AnimationClip::new("ms/nx/native")
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
  Native({
    image: first.image,
    layout,
    graph: graph_handle,
    node: nodes[0],
    anchor: anchor_from_origin(first.origin, first.size),
  })
}

///|
fn is_native_eligible_steps(steps : Array[AnimationStep]) -> Bool {
  guard steps.length() > 0 else { return false }
  let first = steps[0]
  for step in steps {
    if step.image != first.image {
      return false
    }
    if step.size != first.size {
      return false
    }
    if step.origin != first.origin {
      return false
    }
  }
  true
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
  guard animation.playback.steps.length() > 0 else {
    return @sprite.Sprite::from_color(
      white_with_alpha(alpha),
      @math.Vec2(1.0, 1.0),
    )
  }
  let step = animation.playback.steps[0]
  let flip_x = transform.a < 0.0
  @sprite.Sprite::new(
    image=Some(step.image),
    rect=Some(step.rect),
    custom_size=Some(step.size),
    anchor=anchor_from_origin(
      @math.Vec2(step.origin.0 - transform.tx, step.origin.1 - transform.ty),
      step.size,
      flip_x~,
    ),
    flip_x~,
    color=white_with_alpha(alpha),
  )
}

///|
pub fn play_animation(
  entity : @entity.Entity,
  animation : Animation,
  loop_? : Bool = animation.playback.loop_,
  transform? : @math.Transform = @math.Transform::identity(),
) -> Unit {
  set_animation_transform(entity, transform)
  match animation.backend {
    Native(native) => {
      @selene_animation.animation_target_ids().set(
        entity,
        @selene_animation.AnimationTargetId::new("self"),
      )
      @selene_animation.animated_bys().set(
        entity,
        @selene_animation.AnimatedBy::new(entity),
      )
      @selene_animation.animation_graph_handles().set(entity, native.graph)
      let player = @selene_animation.animation_players().get_or_init(entity, fn() {
        @selene_animation.AnimationPlayer::new()
      })
      let repeat = if loop_ {
        @selene_animation.RepeatAnimation::Forever
      } else {
        @selene_animation.RepeatAnimation::Never
      }
      ignore(player.play(native.node, repeat~))
      match @sprite.sprites().get(entity) {
        Some(sprite) =>
          @sprite.sprites().set(entity, {
            ..sprite,
            image: Some(native.image),
            texture_atlas: Some(@sprite.TextureAtlas::new(native.layout)),
            anchor: if transform.a < 0.0 {
              mirror_anchor_x(native.anchor)
            } else {
              native.anchor
            },
          })
        None =>
          @sprite.sprites().set(
            entity,
            @sprite.Sprite::new(
              image=Some(native.image),
              texture_atlas=Some(@sprite.TextureAtlas::new(native.layout)),
              anchor=if transform.a < 0.0 {
                mirror_anchor_x(native.anchor)
              } else {
                native.anchor
              },
              flip_x=transform.a < 0.0,
            ),
          )
      }
      scripted_states.remove(entity)
    }
    Scripted => {
      scripted_states.set(entity, {
        animation,
        step_index: 0,
        step_elapsed: 0.0,
        speed: 1.0,
        finished: false,
      })
      apply_scripted_step(entity, scripted_states.get(entity).unwrap())
    }
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
  if scripted_states.get(entity) is Some(state) {
    state.speed = safe
  }
  if @selene_animation.animation_players().get(entity) is Some(player) {
    for _, pair in player.playing_animations() {
      let (_, active) = pair
      ignore(active.set_speed(safe))
    }
  }
}

///|
pub fn is_animation_finished(entity : @entity.Entity) -> Bool {
  if scripted_states.get(entity) is Some(state) {
    return state.finished
  }
  match @selene_animation.animation_players().get(entity) {
    Some(player) => player.all_finished()
    None => true
  }
}

///|
pub fn current_frame_index(entity : @entity.Entity) -> Int {
  if scripted_states.get(entity) is Some(state) {
    return state.step_index
  }
  match @sprite.sprites().get(entity) {
    Some(sprite) =>
      match sprite.texture_atlas {
        Some(atlas) => atlas.index
        None => 0
      }
    None => 0
  }
}

///|
pub fn stop_animation(entity : @entity.Entity) -> Unit {
  scripted_states.remove(entity)
  if @selene_animation.animation_players().get(entity) is Some(player) {
    ignore(player.stop_all())
  }
}

///|
pub fn animation_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  let pairs = scripted_states.to_array()
  for _, pair in pairs {
    let (entity, state) = pair
    if !entity.is_alive() {
      scripted_states.remove(entity)
      continue
    }
    if state.finished || state.animation.playback.steps.is_empty() {
      continue
    }
    let step = state.animation.playback.steps[state.step_index]
    let duration = if step.duration <= 0.0 { 0.001 } else { step.duration }
    state.step_elapsed += delta * state.speed
    if state.step_elapsed >= duration {
      state.step_elapsed -= duration
      state.step_index += 1
      if state.step_index >= state.animation.playback.steps.length() {
        if state.animation.playback.loop_ {
          state.step_index = 0
        } else {
          state.step_index = state.animation.playback.steps.length() - 1
          state.finished = true
        }
      }
      apply_scripted_step(entity, state)
    }
  }
}

///|
fn apply_scripted_step(entity : @entity.Entity, state : ScriptedState) -> Unit {
  let step = state.animation.playback.steps[state.step_index]
  match @sprite.sprites().get(entity) {
    Some(sprite) =>
      @sprite.sprites().set(entity, {
        ..sprite,
        image: Some(step.image),
        rect: Some(step.rect),
        custom_size: Some(step.size),
        anchor: anchor_from_origin(step.origin, step.size, flip_x=sprite.flip_x),
      })
    None =>
      @sprite.sprites().set(
        entity,
        @sprite.Sprite::new(
          image=Some(step.image),
          rect=Some(step.rect),
          custom_size=Some(step.size),
          anchor=anchor_from_origin(step.origin, step.size),
        ),
      )
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
