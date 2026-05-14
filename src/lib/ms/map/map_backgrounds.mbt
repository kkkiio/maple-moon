///|
/// MapleStory background rendering type encoded by NX `back/type`.
pub(all) enum NxBackgroundType {
  /// Static background with no repeat.
  BG_NORMAL = 0
  /// Horizontal tiled background. Spans the viewport horizontally.
  HTILED = 1
  /// Vertical tiled background. Spans the viewport vertically.
  VTILED = 2
  /// Tiled background. Spans the viewport in both directions.
  TILED = 3
  /// Horizontal moving tiled background.
  HMOVEA = 4
  /// Vertical moving tiled background.
  VMOVEA = 5
  /// Horizontal moving background repeated in both axes.
  HMOVEB = 6
  /// Vertical moving background repeated in both axes.
  VMOVEB = 7
} derive(Debug)

///|
/// Return the original NX integer value for a background type.
pub fn NxBackgroundType::int_value(self : NxBackgroundType) -> Int = "%identity"

///|
/// Parse a MapleStory NX background type id.
pub fn NxBackgroundType::from_int(id : Int) -> NxBackgroundType? {
  let t = match id {
    0 => BG_NORMAL
    1 => HTILED
    2 => VTILED
    3 => TILED
    4 => HMOVEA
    5 => VMOVEA
    6 => HMOVEB
    7 => VMOVEB
    _ => return None
  }
  Some(t)
}

///|
let tiled_background_motion_states_worlds : Map[
  UInt,
  Map[@entity.Entity, TiledBackgroundMotionState],
] = {}

///|
let maple_camera_y_offset = 80.0

///|
priv struct TiledBackgroundMotionState {
  layer_entity : @entity.Entity
  tile_entities : Array[@entity.Entity]
  tile_counts : (Int, Int)
  image_size : @selene_math.Vec2
  layer_z : Int
  clip : @resource.SeleneClip?
  sprite_template : @sprite.Sprite
  background_type : NxBackgroundType
  base_screen_offset : @selene_math.Vec2
  moving_world_pos : @selene_math.Vec2
  ratio : @selene_math.Vec2
  speed : @selene_math.Vec2
  moving_axis : (Bool, Bool)
  repeat : (Bool, Bool)
  tile_step : @selene_math.Vec2
  animation_elapsed_ms : Double
  base_alpha : Double
  alpha_from : Double?
  alpha_to : Double?
  alpha_duration_ms : Double?
  frame_durations_ms : Array[Int]
  frame_alphas : Array[Double]
}

///|
fn tiled_property_int_optional(
  layer : @tiled.TiledLayer,
  name : String,
) -> Int? {
  match layer.property(name) {
    Some(@tiled.TiledPropertyValue::Int(value)) => Some(value)
    Some(@tiled.TiledPropertyValue::Float(value)) => Some(value.to_int())
    Some(@tiled.TiledPropertyValue::String(value)) => {
      let parsed = try? @string.parse_int(value)
      match parsed {
        Ok(parsed) => Some(parsed)
        Err(_) => None
      }
    }
    Some(_) => None
    None => None
  }
}

///|
fn clamp_u8(value : Int) -> Int {
  if value <= 0 {
    0
  } else if value >= 255 {
    255
  } else {
    value
  }
}

///|
fn background_alpha_pair_from_layer(
  layer : @tiled.TiledLayer,
) -> (Double, Double)? {
  let a0 = tiled_property_int_optional(layer, "a0")
  let a1 = tiled_property_int_optional(layer, "a1")
  match (a0, a1) {
    (Some(from), Some(to)) =>
      Some(
        (clamp_u8(from).to_double() / 255.0, clamp_u8(to).to_double() / 255.0),
      )
    (Some(from), None) => {
      let start = clamp_u8(from)
      Some((start.to_double() / 255.0, (255 - start).to_double() / 255.0))
    }
    (None, Some(to)) => {
      let end_ = clamp_u8(to)
      Some(((255 - end_).to_double() / 255.0, end_.to_double() / 255.0))
    }
    _ => None
  }
}

///|
fn is_static_native_background(
  layer : @tiled.TiledLayer,
  background_type : NxBackgroundType,
  cx : Int,
  cy : Int,
) -> Bool {
  let animated = tiled_property_int_optional(layer, "ani").unwrap_or(0) == 1
  if animated ||
    layer.property("a0") is Some(_) ||
    layer.property("a1") is Some(_) {
    return false
  }
  match background_type {
    BG_NORMAL => true
    HTILED => cx == 0
    VTILED => cy == 0
    TILED => cx == 0 && cy == 0
    HMOVEA | VMOVEA | HMOVEB | VMOVEB => false
  }
}

///|
fn should_use_selene_native_background(
  layer : @tiled.TiledLayer,
  background_type : NxBackgroundType,
  cx : Int,
  cy : Int,
  rx : Int,
  ry : Int,
) -> Bool {
  if !is_static_native_background(layer, background_type, cx, cy) {
    return false
  }
  if rx != 0 || ry != 0 {
    return false
  }
  // Selene's Tiled imagelayer repeat uses the map rectangle as the sprite
  // extent. Maple `Tiled(3)` is viewport-covering, so keep it in runtime.
  !(background_type is TILED)
}

///|
fn resolve_alpha_delay_ms(
  delay_ms : Int?,
  is_map_background? : Bool = false,
) -> Double {
  match delay_ms {
    Some(delay_ms) if delay_ms > 0 => delay_ms.to_double()
    _ => if is_map_background { 2500.0 } else { 100.0 }
  }
}

///|
fn parse_background_index(name : String, prefix : String) -> Int? {
  if !name.has_prefix(prefix) {
    return None
  }
  let suffix = name[prefix.length():name.length()].to_owned()
  let parsed = try? @string.parse_int(suffix)
  match parsed {
    Ok(index) => Some(index)
    Err(_) => None
  }
}

///|
fn is_background_image_layer(name : String) -> Bool {
  parse_background_index(name, "background_back_") is Some(_) ||
  parse_background_index(name, "background_front_") is Some(_)
}

///|
fn maple_background_move_speed(ratio : Int) -> Double {
  (ratio * @logic_fps.LOGIC_FPS).to_double() / 16.0
}

///|
fn maple_background_axis_mode(
  background_type : NxBackgroundType,
  axis : @selene_math.Axis,
  ratio : Int,
) -> (Bool, Double, Double) {
  if (
      background_type is NxBackgroundType::HMOVEA ||
      background_type is NxBackgroundType::HMOVEB
    ) &&
    axis is @selene_math.X {
    return (true, 0.0, maple_background_move_speed(ratio))
  }
  if (
      background_type is NxBackgroundType::VMOVEA ||
      background_type is NxBackgroundType::VMOVEB
    ) &&
    axis is @selene_math.Y {
    return (true, 0.0, maple_background_move_speed(ratio))
  }
  (false, ratio.to_double() / 100.0, 0.0)
}

///|
fn maple_background_repeat_axes(
  background_type : NxBackgroundType,
) -> (Bool, Bool) {
  match background_type {
    BG_NORMAL => (false, false)
    HTILED | HMOVEA => (true, false)
    VTILED | VMOVEA => (false, true)
    TILED | HMOVEB | VMOVEB => (true, true)
  }
}

///|
fn maple_background_axis_screen(
  camera_top_left : Double,
  view_half : Double,
  base_screen_offset : Double,
  moving_world_pos : Double,
  ratio : Double,
  moving : Bool,
) -> Double {
  if moving {
    return moving_world_pos - camera_top_left
  }
  base_screen_offset + ratio * (camera_top_left + view_half) + view_half
}

///|
fn wrap_tiled_screen(value : Double, step : Double) -> Double {
  if step <= 0.0 {
    return value
  }
  let mut wrapped = value
  while wrapped > 0.0 {
    wrapped -= step
  }
  while wrapped < -step {
    wrapped += step
  }
  wrapped
}

///|
fn layer_alpha_sample(
  frame_alphas : Array[Double],
  frame_durations_ms : Array[Int],
  elapsed_ms : Double,
) -> Double {
  if frame_alphas.is_empty() || frame_durations_ms.is_empty() {
    return 1.0
  }
  let frame_count = if frame_alphas.length() < frame_durations_ms.length() {
    frame_alphas.length()
  } else {
    frame_durations_ms.length()
  }
  if frame_count <= 0 {
    return 1.0
  }
  let mut total_ms = 0
  for i = 0; i < frame_count; i = i + 1 {
    let duration = frame_durations_ms[i]
    total_ms += if duration <= 0 { 1 } else { duration }
  }
  if total_ms <= 0 {
    return frame_alphas[0]
  }
  let elapsed_mod = if elapsed_ms <= 0.0 {
    0.0
  } else {
    elapsed_ms % total_ms.to_double()
  }
  let mut acc = 0.0
  for i = 0; i < frame_count; i = i + 1 {
    let duration = frame_durations_ms[i]
    let step_ms = if duration <= 0 { 1.0 } else { duration.to_double() }
    acc += step_ms
    if elapsed_mod < acc || i == frame_count - 1 {
      return frame_alphas[i]
    }
  }
  frame_alphas[frame_count - 1]
}

///|
fn property_alpha_sample(
  alpha_from : Double?,
  alpha_to : Double?,
  duration_ms : Double?,
  elapsed_ms : Double,
) -> Double {
  guard alpha_from is Some(alpha_from) &&
    alpha_to is Some(alpha_to) &&
    duration_ms is Some(duration_ms) else {
    return 1.0
  }
  if duration_ms <= 0.0 {
    return alpha_to
  }
  let elapsed_mod = if elapsed_ms <= 0.0 {
    0.0
  } else {
    elapsed_ms % duration_ms
  }
  let progress = elapsed_mod / duration_ms
  alpha_from + (alpha_to - alpha_from) * progress
}

///|
fn clamp01(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else if value >= 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn ceil_div_double(value : Double, step : Double) -> Int {
  if value <= 0.0 {
    return 0
  }
  let base = (value / step).to_int()
  if base.to_double() * step < value {
    base + 1
  } else {
    base
  }
}

///|
fn background_tile_count_for_axis(
  repeat : Bool,
  view_size : Double,
  step : Double,
) -> Int {
  if !repeat {
    return 1
  }
  ceil_div_double(view_size, @cmp.maximum(step, 1.0)) + 3
}

///|
fn background_tile_counts(
  repeat : (Bool, Bool),
  view_size : @selene_math.Vec2,
  tile_step : @selene_math.Vec2,
) -> (Int, Int) {
  (
    background_tile_count_for_axis(
      repeat.0,
      view_size[@selene_math.X],
      tile_step[@selene_math.X],
    ),
    background_tile_count_for_axis(
      repeat.1,
      view_size[@selene_math.Y],
      tile_step[@selene_math.Y],
    ),
  )
}

///|
fn background_frame_index_sample(
  frame_durations_ms : Array[Int],
  elapsed_ms : Double,
) -> Int {
  if frame_durations_ms.is_empty() {
    return 0
  }
  let mut total_ms = 0
  for duration in frame_durations_ms {
    total_ms += if duration <= 0 { 1 } else { duration }
  }
  if total_ms <= 0 {
    return 0
  }
  let elapsed_mod = if elapsed_ms <= 0.0 {
    0.0
  } else {
    elapsed_ms % total_ms.to_double()
  }
  let mut acc = 0.0
  for i, duration in frame_durations_ms {
    acc += if duration <= 0 { 1.0 } else { duration.to_double() }
    if elapsed_mod < acc || i == frame_durations_ms.length() - 1 {
      return i
    }
  }
  frame_durations_ms.length() - 1
}

///|
fn background_sprite_for_frame(
  state : TiledBackgroundMotionState,
  frame_index : Int,
  alpha : Double,
) -> @sprite.Sprite {
  match state.clip {
    Some(clip) => {
      let atlas = @sprite.TextureAtlas(clip.layout, index=frame_index)
      {
        ..state.sprite_template,
        image: Some(clip.image),
        texture_atlas: Some(atlas),
        rect: None,
        custom_size: Some(state.image_size),
        image_mode: @sprite.SpriteImageMode::Auto,
        color: { ..state.sprite_template.color, a: alpha },
      }
    }
    None =>
      {
        ..state.sprite_template,
        texture_atlas: None,
        custom_size: Some(state.image_size),
        image_mode: @sprite.SpriteImageMode::Auto,
        color: { ..state.sprite_template.color, a: alpha },
      }
  }
}

///|
fn ensure_background_tiles(
  state : TiledBackgroundMotionState,
  tile_counts : (Int, Int),
  sprite : @sprite.Sprite,
) -> TiledBackgroundMotionState {
  if state.tile_counts == tile_counts {
    for entity in state.tile_entities {
      @sprite.sprites().set(entity, sprite)
    }
    return state
  }
  for entity in state.tile_entities {
    entity.destroy()
  }
  let tile_entities : Array[@entity.Entity] = []
  for _ in 0..<(tile_counts.0 * tile_counts.1) {
    let child = state.layer_entity.spawn_child()
    set_entity_z(child, state.layer_z)
    @sprite.sprites().set(child, sprite)
    tile_entities.push(child)
  }
  { ..state, tile_entities, tile_counts }
}

///|
fn replace_aseprite_suffix(path : String) -> String? {
  if path.has_suffix(".aseprite") {
    Some(path.strip_suffix(".aseprite").unwrap().to_owned() + ".json")
  } else {
    None
  }
}

///|
fn create_background_motion_states(
  tile_map : @tiled.TiledMap,
  root : @entity.Entity,
  clips_by_entity : Map[@entity.Entity, @resource.SeleneClip],
) -> Map[@entity.Entity, TiledBackgroundMotionState] raise {
  ignore(tile_map)
  let states : Map[@entity.Entity, TiledBackgroundMotionState] = Map([])
  for layer_entity, instance in @tiled.tiled_image_layer_instances() {
    guard instance.map_entity == root &&
      is_background_image_layer(instance.layer.name) else {
      continue
    }
    let layer = instance.layer
    guard tiled_property_int_optional(layer, "type").bind(v => {
        NxBackgroundType::from_int(v)
      })
      is Some(background_type) else {
      continue
    }
    let rx = tiled_property_int_optional(layer, "rx").unwrap_or(0)
    let ry = tiled_property_int_optional(layer, "ry").unwrap_or(0)
    let cx = tiled_property_int_optional(layer, "cx").unwrap_or(0)
    let cy = tiled_property_int_optional(layer, "cy").unwrap_or(0)
    if should_use_selene_native_background(
        layer, background_type, cx, cy, rx, ry,
      ) {
      continue
    }
    guard @sprite.sprites().get(layer_entity) is Some(sprite_template) else {
      fail("missing sprite for background layer=\{layer.name}")
    }
    let clip = clips_by_entity.get(layer_entity)
    let raw_image_width = match clip {
      Some(clip) => clip.dimensions.x
      None => instance.image_layer.image_width.unwrap_or(1)
    }
    let raw_image_height = match clip {
      Some(clip) => clip.dimensions.y
      None => instance.image_layer.image_height.unwrap_or(1)
    }
    let image_width = raw_image_width.max(1)
    let image_height = raw_image_height.max(1)
    let step_x = if cx > 0 { cx } else { image_width }
    let step_y = if cy > 0 { cy } else { image_height }
    @sprite.sprites().remove(layer_entity)
    let layer_z = @transform.transforms()
      .get(layer_entity)
      .map(fn(transform) { transform.translation.z.to_int() })
      .unwrap_or(0)
    @transform.transforms().set(
      layer_entity,
      @transform.Transform::from_xyz(0.0, 0.0, layer_z.to_double()),
    )
    let x_mode = maple_background_axis_mode(background_type, @selene_math.X, rx)
    let y_mode = maple_background_axis_mode(background_type, @selene_math.Y, ry)
    let repeat = maple_background_repeat_axes(background_type)
    let property_alpha = background_alpha_pair_from_layer(layer)
    let base_alpha = clamp_u8(
        tiled_property_int_optional(layer, "a").unwrap_or(255),
      ).to_double() /
      255.0
    let frame_durations_ms = clip
      .map(fn(clip) { clip.frame_durations_ms })
      .unwrap_or([100])
    let frame_alphas = if property_alpha is Some(_) {
      [1.0]
    } else {
      clip.map(fn(clip) { clip.frame_alphas }).unwrap_or([1.0])
    }
    states[layer_entity] = {
      layer_entity,
      tile_entities: [],
      tile_counts: (0, 0),
      image_size: @selene_math.Vec2(
        image_width.to_double(),
        image_height.to_double(),
      ),
      layer_z,
      clip,
      sprite_template,
      background_type,
      base_screen_offset: @selene_math.Vec2(layer.offset_x, layer.offset_y),
      moving_world_pos: @selene_math.Vec2(layer.offset_x, layer.offset_y),
      ratio: @selene_math.Vec2(x_mode.1, y_mode.1),
      speed: @selene_math.Vec2(x_mode.2, y_mode.2),
      moving_axis: (x_mode.0, y_mode.0),
      repeat,
      tile_step: @selene_math.Vec2(step_x.to_double(), step_y.to_double()),
      animation_elapsed_ms: 0.0,
      base_alpha,
      alpha_from: property_alpha.map(fn(pair) { pair.0 }),
      alpha_to: property_alpha.map(fn(pair) { pair.1 }),
      alpha_duration_ms: property_alpha.map(fn(_) {
        resolve_alpha_delay_ms(
          tiled_property_int_optional(layer, "delay"),
          is_map_background=true,
        )
      }),
      frame_durations_ms,
      frame_alphas,
    }
  }
  states
}

///|
fn collect_background_animation_clips(
  image_layer_events : Array[@tiled.TiledImageLayerSpawnedEvent],
  root : @entity.Entity,
  background_animations : Map[String, @resource.SeleneClip],
) -> Map[@entity.Entity, @resource.SeleneClip] raise {
  let clips_by_entity : Map[@entity.Entity, @resource.SeleneClip] = {}
  for event in image_layer_events {
    if event.map_entity == root {
      if background_animations.get(event.layer.name) is Some(clip) {
        clips_by_entity[event.layer_entity] = clip
      } else if event.image_layer.image.bind(replace_aseprite_suffix)
        is Some(json_path) {
        fail(
          "missing preloaded background animation for layer=\{event.layer.name}, json=\{json_path}",
        )
      }
    }
  }
  clips_by_entity
}

///|
fn set_tiled_backgrounds(
  world : @ecs.World,
  map : @tiled.TiledMap,
  root : @entity.Entity,
  image_layer_events : Array[@tiled.TiledImageLayerSpawnedEvent],
  background_animations : Map[String, @resource.SeleneClip],
) -> Unit raise {
  let clips_by_entity = collect_background_animation_clips(
    image_layer_events, root, background_animations,
  )
  let states = create_background_motion_states(map, root, clips_by_entity)
  tiled_background_motion_states_worlds[world.id] = states
}

///|
fn clear_tiled_backgrounds(world : @ecs.World) -> Unit {
  tiled_background_motion_states_worlds.remove(world.id)
}

///|
fn disable_selene_parallax_for_backgrounds(
  event : @tiled.TiledImageLayerSpawnedEvent,
) -> Unit {
  guard is_background_image_layer(event.layer.name) else { return }
  let layer = event.layer
  guard tiled_property_int_optional(layer, "type").bind(v => {
      NxBackgroundType::from_int(v)
    })
    is Some(background_type) else {
    return
  }
  let cx = tiled_property_int_optional(layer, "cx").unwrap_or(0)
  let cy = tiled_property_int_optional(layer, "cy").unwrap_or(0)
  let rx = tiled_property_int_optional(layer, "rx").unwrap_or(0)
  let ry = tiled_property_int_optional(layer, "ry").unwrap_or(0)
  if !should_use_selene_native_background(
      layer, background_type, cx, cy, rx, ry,
    ) {
    @tiled.tiled_parallax_layers().remove(event.layer_entity)
  }
}

///|
/// Updates Maple backgrounds.
pub fn tiled_background_motion_system(world : @ecs.World) -> Unit {
  guard tiled_background_motion_states_worlds.get(world.id)
    is Some(motion_states) &&
    !motion_states.is_empty() else {
    return
  }
  let delta = @time.delta()
  let camera_top_left = @camera.current_camera_top_left()
  let screen_size = @system.get_screen_size()
  let bottom_right = @camera.viewport_to_world(screen_size)
  let view_size = bottom_right - camera_top_left
  let view_half = @selene_math.Vec2(
    view_size[@selene_math.X] * 0.5,
    view_size[@selene_math.Y] * 0.5,
  )
  let camera_for_formula = @selene_math.Vec2(
    camera_top_left[@selene_math.X],
    camera_top_left[@selene_math.Y] - maple_camera_y_offset,
  )
  for layer_entity, state in motion_states {
    ignore(state.background_type)
    let next_animation_elapsed_ms = state.animation_elapsed_ms + delta * 1000.0
    let frame_index = background_frame_index_sample(
      state.frame_durations_ms,
      next_animation_elapsed_ms,
    )
    let animated_alpha = if state.alpha_from is Some(_) {
      property_alpha_sample(
        state.alpha_from,
        state.alpha_to,
        state.alpha_duration_ms,
        next_animation_elapsed_ms,
      )
    } else {
      layer_alpha_sample(
        state.frame_alphas,
        state.frame_durations_ms,
        next_animation_elapsed_ms,
      )
    }
    let a = clamp01(state.base_alpha * animated_alpha)
    let sampled_sprite = background_sprite_for_frame(state, frame_index, a)
    let tile_counts = background_tile_counts(
      state.repeat,
      view_size,
      state.tile_step,
    )
    let state = ensure_background_tiles(state, tile_counts, sampled_sprite)

    let mut next_moving_world_x = state.moving_world_pos[@selene_math.X]
    if state.moving_axis.0 {
      next_moving_world_x += state.speed[@selene_math.X] * delta
    }
    let mut next_moving_world_y = state.moving_world_pos[@selene_math.Y]
    if state.moving_axis.1 {
      next_moving_world_y += state.speed[@selene_math.Y] * delta
    }
    let screen_x = maple_background_axis_screen(
      camera_for_formula[@selene_math.X],
      view_half[@selene_math.X],
      state.base_screen_offset[@selene_math.X],
      next_moving_world_x,
      state.ratio[@selene_math.X],
      state.moving_axis.0,
    )
    let screen_y = maple_background_axis_screen(
      camera_for_formula[@selene_math.Y],
      view_half[@selene_math.Y],
      state.base_screen_offset[@selene_math.Y],
      next_moving_world_y,
      state.ratio[@selene_math.Y],
      state.moving_axis.1,
    )
    let wrapped_screen_x = if state.repeat.0 {
      wrap_tiled_screen(screen_x, state.tile_step[@selene_math.X])
    } else {
      screen_x
    }
    let wrapped_screen_y = if state.repeat.1 {
      wrap_tiled_screen(screen_y, state.tile_step[@selene_math.Y])
    } else {
      screen_y
    }
    let world_pos = @selene_math.Vec2(
      camera_top_left[@selene_math.X] + wrapped_screen_x,
      camera_top_left[@selene_math.Y] + wrapped_screen_y,
    )
    motion_states.set(layer_entity, {
      ..state,
      animation_elapsed_ms: next_animation_elapsed_ms,
      moving_world_pos: @selene_math.Vec2(
        next_moving_world_x, next_moving_world_y,
      ),
    })
    for index, tile_entity in state.tile_entities {
      let ix = index % state.tile_counts.0
      let iy = index / state.tile_counts.0
      let pos = if state.repeat.0 && state.repeat.1 {
        world_pos +
        @selene_math.Vec2(
          ix.to_double() * state.tile_step[@selene_math.X],
          iy.to_double() * state.tile_step[@selene_math.Y],
        )
      } else if state.repeat.0 {
        world_pos +
        @selene_math.Vec2(ix.to_double() * state.tile_step[@selene_math.X], 0.0)
      } else if state.repeat.1 {
        world_pos +
        @selene_math.Vec2(0.0, iy.to_double() * state.tile_step[@selene_math.Y])
      } else {
        world_pos
      }
      @transform2d.set_xy(tile_entity, pos)
    }
  }
}

///|
test "background axis mode mapping covers type0~7" {
  let x0 = maple_background_axis_mode(BG_NORMAL, @selene_math.X, -40)
  let y0 = maple_background_axis_mode(BG_NORMAL, @selene_math.Y, -5)
  assert_false(x0.0)
  assert_false(y0.0)
  assert_eq(x0.1, -0.4)
  assert_eq(y0.1, -0.05)
  assert_eq(x0.2, 0.0)
  assert_eq(y0.2, 0.0)

  let x1 = maple_background_axis_mode(HTILED, @selene_math.X, 30)
  let y1 = maple_background_axis_mode(HTILED, @selene_math.Y, -20)
  assert_false(x1.0)
  assert_false(y1.0)
  assert_eq(x1.1, 0.3)
  assert_eq(y1.1, -0.2)

  let x2 = maple_background_axis_mode(VTILED, @selene_math.X, 25)
  let y2 = maple_background_axis_mode(VTILED, @selene_math.Y, -45)
  assert_false(x2.0)
  assert_false(y2.0)
  assert_eq(x2.1, 0.25)
  assert_eq(y2.1, -0.45)

  let x3 = maple_background_axis_mode(TILED, @selene_math.X, -70)
  let y3 = maple_background_axis_mode(TILED, @selene_math.Y, 10)
  assert_false(x3.0)
  assert_false(y3.0)
  assert_eq(x3.1, -0.7)
  assert_eq(y3.1, 0.1)

  let x4 = maple_background_axis_mode(HMOVEA, @selene_math.X, -5)
  let y4 = maple_background_axis_mode(HMOVEA, @selene_math.Y, -3)
  assert_true(x4.0)
  assert_false(y4.0)
  assert_eq(x4.1, 0.0)
  assert_eq(y4.1, -0.03)
  assert_true(x4.2 < 0.0)
  assert_eq(y4.2, 0.0)

  let x5 = maple_background_axis_mode(VMOVEA, @selene_math.X, -7)
  let y5 = maple_background_axis_mode(VMOVEA, @selene_math.Y, -9)
  assert_false(x5.0)
  assert_true(y5.0)
  assert_eq(x5.1, -0.07)
  assert_eq(y5.1, 0.0)
  assert_eq(x5.2, 0.0)
  assert_true(y5.2 < 0.0)

  let x6 = maple_background_axis_mode(HMOVEB, @selene_math.X, -11)
  let y6 = maple_background_axis_mode(HMOVEB, @selene_math.Y, -12)
  assert_true(x6.0)
  assert_false(y6.0)
  assert_eq(x6.1, 0.0)
  assert_eq(y6.1, -0.12)
  assert_true(x6.2 < 0.0)

  let x7 = maple_background_axis_mode(VMOVEB, @selene_math.X, -13)
  let y7 = maple_background_axis_mode(VMOVEB, @selene_math.Y, -14)
  assert_false(x7.0)
  assert_true(y7.0)
  assert_eq(x7.1, -0.13)
  assert_eq(y7.1, 0.0)
  assert_true(y7.2 < 0.0)
}

///|
test "parallax screen axis matches exported Tiled coordinate space" {
  let screen_x = maple_background_axis_screen(
    1691.0, 400.0, -66.0, 0.0, -0.4, false,
  )
  let expected = -66.0 + -40.0 * (400.0 + 1691.0) / 100.0 + 400.0
  assert_true((screen_x - expected).abs() < 0.000001)

  let camera_top_left_y = 733.0
  let view_half_y = 300.0
  let screen_y = maple_background_axis_screen(
    camera_top_left_y - maple_camera_y_offset,
    view_half_y,
    -12.0,
    0.0,
    -0.5,
    false,
  )
  let expected_y = -12.0 +
    -50.0 * (view_half_y + camera_top_left_y - maple_camera_y_offset) / 100.0 +
    view_half_y
  assert_true((screen_y - expected_y).abs() < 0.000001)
}

///|
test "background tile count uses ceil viewport coverage plus margin" {
  assert_eq(background_tile_count_for_axis(false, 801.0, 256.0), 1)
  assert_eq(background_tile_count_for_axis(true, 800.0, 256.0), 7)
  assert_eq(background_tile_count_for_axis(true, 512.0, 256.0), 5)
  assert_true(
    background_tile_counts(
      (true, true),
      @selene_math.Vec2(800.0, 600.0),
      @selene_math.Vec2(256.0, 128.0),
    ) ==
    (7, 8),
  )
}

///|
fn test_background_layer(properties : Json) -> @tiled.TiledLayer raise {
  let map = @tiled.TiledMap::from_tiled_json({
    "type": "map",
    "width": 1,
    "height": 1,
    "tilewidth": 1,
    "tileheight": 1,
    "layers": [
      {
        "id": 1,
        "name": "background_back_0",
        "type": "imagelayer",
        "opacity": 1,
        "visible": true,
        "offsetx": 0,
        "offsety": 0,
        "parallaxx": 1,
        "parallaxy": 1,
        "properties": properties,
      },
    ],
  })
  match map.layer("background_back_0") {
    Some(layer) => layer
    None => fail("missing test background layer")
  }
}

///|
fn test_background_int_property(name : String, value : Int) -> Json {
  { "name": name, "type": "int", "value": value }
}

///|
test "static native background classification keeps selene-compatible layers" {
  let static_layer = test_background_layer([])
  assert_true(is_static_native_background(static_layer, BG_NORMAL, 64, 32))
  assert_true(is_static_native_background(static_layer, HTILED, 0, 32))
  assert_false(is_static_native_background(static_layer, HTILED, 64, 32))
  assert_true(is_static_native_background(static_layer, VTILED, 64, 0))
  assert_false(is_static_native_background(static_layer, VTILED, 64, 32))
  assert_true(is_static_native_background(static_layer, TILED, 0, 0))
  assert_false(is_static_native_background(static_layer, TILED, 64, 0))
  assert_false(is_static_native_background(static_layer, TILED, 0, 32))
  assert_false(is_static_native_background(static_layer, TILED, 64, 32))
}

///|
test "animated moving or alpha tween backgrounds use runtime branch" {
  let static_layer = test_background_layer([])
  assert_false(is_static_native_background(static_layer, HMOVEA, 0, 0))
  assert_false(is_static_native_background(static_layer, VMOVEA, 0, 0))
  assert_false(is_static_native_background(static_layer, HMOVEB, 0, 0))
  assert_false(is_static_native_background(static_layer, VMOVEB, 0, 0))

  let animated_layer = test_background_layer([
    test_background_int_property("ani", 1),
  ])
  assert_false(is_static_native_background(animated_layer, BG_NORMAL, 0, 0))
  assert_false(is_static_native_background(animated_layer, HTILED, 0, 0))

  let alpha_from_layer = test_background_layer([
    test_background_int_property("a0", 64),
  ])
  let alpha_to_layer = test_background_layer([
    test_background_int_property("a1", 192),
  ])
  assert_false(is_static_native_background(alpha_from_layer, BG_NORMAL, 0, 0))
  assert_false(is_static_native_background(alpha_to_layer, TILED, 0, 0))
}

///|
test "selene native branch excludes Maple runtime positioning cases" {
  let static_layer = test_background_layer([])
  assert_true(
    should_use_selene_native_background(static_layer, BG_NORMAL, 0, 0, 0, 0),
  )
  assert_true(
    should_use_selene_native_background(static_layer, HTILED, 0, 0, 0, 0),
  )
  assert_true(
    should_use_selene_native_background(static_layer, VTILED, 0, 0, 0, 0),
  )
  assert_false(
    should_use_selene_native_background(static_layer, BG_NORMAL, 0, 0, -30, 0),
  )
  assert_false(
    should_use_selene_native_background(static_layer, HTILED, 0, 0, 0, -60),
  )
  assert_false(
    should_use_selene_native_background(static_layer, TILED, 0, 0, 0, 0),
  )
}

///|
test "background frame sampler is layer stable" {
  let frame = background_frame_index_sample([100, 200, 300], 250.0)
  let same_layer_other_tile = background_frame_index_sample(
    [100, 200, 300],
    250.0,
  )
  assert_eq(frame, 1)
  assert_eq(same_layer_other_tile, frame)
}

///|
test "repeat wrap keeps value in [-step, 0]" {
  assert_eq(wrap_tiled_screen(150.0, 1024.0), -874.0)
  assert_eq(wrap_tiled_screen(-1400.0, 1024.0), -376.0)
  assert_eq(wrap_tiled_screen(0.0, 1024.0), 0.0)
  assert_eq(wrap_tiled_screen(-1024.0, 1024.0), -1024.0)
}

///|
test "property alpha sample interpolates continuously and loops" {
  let half = property_alpha_sample(Some(0.2), Some(0.6), Some(2000.0), 1000.0)
  assert_true((half - 0.4).abs() < 0.000001)
  let looped = property_alpha_sample(Some(0.1), Some(0.5), Some(2500.0), 3750.0)
  assert_true((looped - 0.3).abs() < 0.000001)
}
