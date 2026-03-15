///|
using @resource {nx_texture_to_selene_picture}

///|
pub(all) enum BackgroundType {
  BG_NORMAL = 0
  /// horizontal tiled background. spans the viewport horizontally.
  HTILED = 1
  /// vertical tiled background. spans the viewport vertically.
  VTILED = 2
  /// tiled background. spans the viewport in both directions.
  TILED = 3
  /// horizontal moving tiled background
  HMOVEA = 4
  /// vertical moving tiled background
  VMOVEA = 5
  // HMOVEB = 6
  // VMOVEB = 7
} derive(Eq, Compare, Show, ToJson)

///|
pub fn BackgroundType::int_value(self : BackgroundType) -> Int = "%identity"

///|
pub fn BackgroundType::from_int(id : Int) -> BackgroundType? {
  let t = match id {
    0 => BackgroundType::BG_NORMAL
    1 => BackgroundType::HTILED
    2 => BackgroundType::VTILED
    3 => BackgroundType::TILED
    4 => BackgroundType::HMOVEA
    5 => BackgroundType::VMOVEA
    // 6 => BackgroundType::HMOVEB
    // 7 => BackgroundType::VMOVEB
    _ => return None
  }
  Some(t)
}

///|
/// Background in a map. Position is relative to the viewport origin.
pub struct NxBackground {
  a : Int
  /// whether the background is animated
  ani : Bool
  /// background set
  bS : String
  /// horizontal tiling step in pixels. `0` means fallback to the frame width.
  cx : Int
  /// vertical tiling step in pixels. `0` means fallback to the frame height.
  cy : Int
  f : Bool // TODO: what does it mean?
  /// whether the background is a foreground
  front : Bool
  /// number of the background in the background set
  no : Int
  /// parallax ratio of horizontal movement
  rx : Int
  /// parallax ratio of vertical movement
  ry : Int
  type_ : BackgroundType
  x : Int
  y : Int
} derive(Show)

///|
pub impl @json.FromJson for NxBackground with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  guard obj
    is {
      "a": Json::Number(a, ..),
      "bS": Json::String(bS),
      "cx": Json::Number(cx, ..),
      "cy": Json::Number(cy, ..),
      "no": Json::Number(no, ..),
      "rx": Json::Number(rx, ..),
      "ry": Json::Number(ry, ..),
      "type": Json::Number(type_, ..),
      "x": Json::Number(x, ..),
      "y": Json::Number(y, ..),
      ..
    } else {
    raise @json.JsonDecodeError((path, "missing background fields"))
  }
  let front = obj is { "front": Json::Number(1, ..), .. }
  let ani = obj is { "ani": Json::Number(1, ..), .. }
  let f = obj is { "f": Json::Number(1, ..), .. }
  {
    a: a.to_int(),
    ani,
    bS,
    cx: cx.to_int(),
    cy: cy.to_int(),
    f,
    front,
    no: no.to_int(),
    rx: rx.to_int(),
    ry: ry.to_int(),
    type_: BackgroundType::from_int(type_.to_int()).unwrap_or_error(
      @json.JsonDecodeError(
        (path.add_key("type"), "unknown background type \{type_}"),
      ),
    ),
    x: x.to_int(),
    y: y.to_int(),
  }
}

///|
test "parse NxBackground" {
  let spec : NxBackground = @json.from_json({
    "a": 255,
    "ani": 0,
    "bS": "",
    "cx": 0,
    "cy": 0,
    "front": 0,
    "no": 0,
    "rx": 0,
    "ry": 0,
    "type": 0,
    "x": 0,
    "y": 0,
  })
  inspect(
    spec,
    content=(
      #|{a: 255, ani: false, bS: "", cx: 0, cy: 0, f: false, front: false, no: 0, rx: 0, ry: 0, type_: BG_NORMAL, x: 0, y: 0}
    ),
  )
}

///|
pub struct BackgroundResource {
  animation : @resource.NxAnimation
  t : BackgroundType
  x : Int
  y : Int
  /// horizontal tiling step in pixels. `0` means fallback to the frame width.
  cx : Int
  /// vertical tiling step in pixels. `0` means fallback to the frame height.
  cy : Int
  rx : Int
  ry : Int
  opacity : Double
  flipped : Bool
}

///|
struct BackgroundAnimationPath {
  animated : Bool
  no : Int
} derive(Show, Eq, Hash)

///|
priv struct BackgroundOpacityFrameSpec {
  start_opacity : Double
  end_opacity : Double
  delay_ms : Int
}

///|
priv struct BackgroundOpacityAnimationSpec {
  frames : Array[BackgroundOpacityFrameSpec]
  zigzag : Bool
}

///|
priv struct BackgroundOpacityAnimationState {
  frames : Array[BackgroundOpacityFrameSpec]
  zigzag : Bool
  opacity : @utils.Linear
  mut frame : Int
  mut frame_step : Int
  mut delay_ms : Int
}

///|
let background_opacity_specs : Ref[Map[String, BackgroundOpacityAnimationSpec]] = Ref::new({},
)

///|
pub fn BackgroundAnimationPath::from_nx(
  background : NxBackground,
) -> BackgroundAnimationPath {
  { animated: background.ani, no: background.no }
}

///|
pub async fn load_background_animation(
  bs_loader : @resource.AsyncLoader,
  background_set_name : String,
  path : BackgroundAnimationPath,
) -> @resource.NxAnimation {
  let { animated, no } = path
  let bg_res = bs_loader.load_resource([
    background_set_name + ".img",
    if animated {
      "ani"
    } else {
      "back"
    },
    no.to_string(),
  ])
  let animation_json = bg_res
  let animation : @resource.NxAnimation = @json.from_json(animation_json)
  background_opacity_specs.val[background_animation_signature(animation)] = background_opacity_animation_spec_from_json(
    animation_json,
  )
  animation
}

///|
pub fn BackgroundResource::new(
  spec : NxBackground,
  animation : @resource.NxAnimation,
) -> BackgroundResource {
  let t = spec.type_
  let opacity = spec.a.to_double() / 255.0
  let flipped = spec.f
  let cx = spec.cx
  let cy = spec.cy
  let rx = spec.rx
  let ry = spec.ry
  let x = spec.x
  let y = spec.y
  { animation, t, x, y, cx, cy, rx, ry, opacity, flipped }
}

///|
/// Background runtime data
struct Background {
  animation : @resource.NxAnimation
  opacity_animation : BackgroundOpacityAnimationState
  base_opacity : Double
  flipped : Bool
  tile_step_x : Int
  tile_step_y : Int
  horizontal_render : BackgroundDirRender
  vertical_render : BackgroundDirRender
}

///|
priv enum BackgroundDirRender {
  /// Normal background.
  ///
  /// - `offset`: screen position of the background
  /// - `parallax_ratio`: parallax ratio of the background
  Normal(offset~ : Double, parallax_ratio~ : Double)
  /// Tiled background. Cover the viewport.
  ///
  /// - `moving_speed`: moving speed of the background in the horizontal and vertical directions (pixels per second)
  /// - `offset`: current screen position of the background
  Tiled(moving_speed~ : Double, mut offset~ : Double)
}

///|
fn Background::from_resource(res : BackgroundResource) -> Background {
  let (frame_w, frame_h) = res.animation.get_size()
  let tile_step_x = if res.cx > 0 { res.cx } else { frame_w.max(1) }
  let tile_step_y = if res.cy > 0 { res.cy } else { frame_h.max(1) }
  let horizontal_render = match res.t {
    BackgroundType::BG_NORMAL
    | BackgroundType::VTILED
    | BackgroundType::VMOVEA =>
      BackgroundDirRender::Normal(
        offset=res.x.to_double(),
        parallax_ratio=res.rx.to_double() / 100.0,
      )
    BackgroundType::TILED | BackgroundType::HTILED | BackgroundType::HMOVEA => {
      // TODO: Figure out why divide 16.0?
      let moving_speed = if res.t is BackgroundType::HMOVEA {
        (res.rx * @logic_fps.LOGIC_FPS).to_double() / 16.0
      } else {
        0.0
      }
      BackgroundDirRender::Tiled(
        moving_speed~,
        offset=wrap_in_range(
          res.x.to_double(),
          start=-tile_step_x.to_double(),
          end=0.0,
        ),
      )
    }
  }
  let vertical_render = match res.t {
    BackgroundType::BG_NORMAL
    | BackgroundType::HTILED
    | BackgroundType::HMOVEA =>
      BackgroundDirRender::Normal(
        offset=res.y.to_double(),
        parallax_ratio=res.ry.to_double() / 100.0,
      )
    BackgroundType::TILED | BackgroundType::VTILED | BackgroundType::VMOVEA => {
      // TODO: Figure out why divide 16.0?
      let moving_speed = if res.t is BackgroundType::VMOVEA {
        (res.ry * @logic_fps.LOGIC_FPS).to_double() / 16.0
      } else {
        0.0
      }
      BackgroundDirRender::Tiled(
        moving_speed~,
        offset=wrap_in_range(
          res.y.to_double(),
          start=-tile_step_y.to_double(),
          end=0.0,
        ),
      )
    }
  }
  {
    animation: res.animation,
    opacity_animation: BackgroundOpacityAnimationState::new(
      background_opacity_specs.val
      .get(background_animation_signature(res.animation))
      .unwrap_or(default_background_opacity_animation_spec()),
    ),
    base_opacity: res.opacity,
    flipped: res.flipped,
    tile_step_x,
    tile_step_y,
    horizontal_render,
    vertical_render,
  }
}

///|
fn new_background_sprite(background : Background, z : Int) -> @sprite.Sprite {
  let { animation, flipped, .. } = background
  let texture = animation.frames[0].texture
  @sprite.Sprite::from_picture(
    nx_texture_to_selene_picture(texture, flip_x=flipped),
    z,
    alpha=background.current_opacity(),
  )
}

///|
fn Background::update(self : Background, delta : Double) -> Unit {
  self.opacity_animation.update((delta * 1000.0).to_int())
}

///|
fn Background::current_opacity(self : Background) -> Double {
  self.base_opacity * self.opacity_animation.current_opacity()
}

///|
/// Calculate the position of a background sprite.
/// 
/// - `background`: the background to update the position of
/// - `camera_pos`: the position of the camera
///
/// Maple client's parallax formula:
/// ```text
/// shift = parallax_ratio * (cam_left + view_half) + view_half
/// screen_pos = origin + shift
/// world_pos = screen_pos + cam_left
/// ```
pub fn new_background_position(
  background : Background,
  camera_pos : @selene_math.Vec2D,
  delta : Double,
) -> @selene_math.Vec2D {
  let view_size = @selene_math.Vec2D(
    @graphics.view_size.0.to_double(),
    @graphics.view_size.1.to_double(),
  )
  let x = match background.horizontal_render {
    BackgroundDirRender::Normal(offset~, parallax_ratio~) =>
      parallax_shift(offset, parallax_ratio, X, camera_pos, view_size)
    BackgroundDirRender::Tiled(moving_speed~, ..) as tiled => {
      let x = move_along_axis(
        tiled.offset,
        moving_speed,
        delta,
        background.tile_step_x.to_double(),
      )
      tiled.offset = x
      camera_pos[X] + tiled.offset
    }
  }
  let y = match background.vertical_render {
    BackgroundDirRender::Normal(offset~, parallax_ratio~) =>
      parallax_shift(offset, parallax_ratio, Y, camera_pos, view_size)
    BackgroundDirRender::Tiled(moving_speed~, ..) as tiled => {
      let y = move_along_axis(
        tiled.offset,
        moving_speed,
        delta,
        background.tile_step_y.to_double(),
      )
      tiled.offset = y
      camera_pos[Y] + tiled.offset
    }
  }
  @selene_math.Vec2D(x, y)
}

///|
/// Calculate the parallax shift(position) for a background.
fn parallax_shift(
  offset : Double,
  parallax_ratio : Double,
  axis : @selene_math.Axis,
  camera_pos : @selene_math.Vec2D,
  view_size : @selene_math.Vec2D,
) -> Double {
  let view_half = view_size[axis] / 2.0
  let camera_center = camera_pos[axis] + view_half
  let shift = camera_center.mul(parallax_ratio) + view_half
  let new_pos = offset + shift + camera_pos[axis]
  new_pos
}

///|
/// Move along an axis, wrap in [-size, 0).
fn move_along_axis(
  offset : Double,
  moving_speed : Double,
  delta : Double,
  size : Double,
) -> Double {
  wrap_in_range(offset + moving_speed * delta, start=-size, end=0.0)
}

///|
test "parallax check map 100000000" {
  let camera_pos = @selene_math.Vec2D(1691, -132) // top-left of the viewport
  let background_ref_json : Json = {
    "a": 255,
    "ani": 0,
    "bS": "grassySoil",
    "cx": 0,
    "cy": 0,
    "f": 0,
    "front": 0,
    "no": 5,
    "rx": -40,
    "ry": -5,
    "type": 0,
    "x": 1982,
    "y": 186,
  }
  let background : NxBackground = @json.from_json(background_ref_json)
  let ratio = @selene_math.Vec2D(
    background.rx.to_double(),
    background.ry.to_double(),
  )
  let position = @selene_math.Vec2D(
    background.x.to_double(),
    background.y.to_double(),
  )
  let view_half = @selene_math.Vec2D(
    @graphics.view_size.0.to_double() / 2.0,
    @graphics.view_size.1.to_double() / 2.0,
  )
  let camera_center = camera_pos + view_half
  let parallax_ratio = ratio.scalar_div(100.0)
  let shift = camera_center.mul(parallax_ratio) + view_half
  let new_pos = position + shift + camera_pos
  let tile_json : Json = { "no": 2, "u": "bsc", "x": 3735, "y": 330, "zM": 4 }
  let tile : NxTileRef = @json.from_json(tile_json)
  let background_json : Json = {
    "__h": 257,
    "__w": 1024,
    "origin": [512, 128],
    "z": 0,
    "__i": "assets/map/back/grass_2.png",
  }
  let background : @resource.NxTexture = @json.from_json(background_json)
  assert_true(
    new_pos.1 + background.h.to_double() - background.origin.y.to_double() >
    tile.y.to_double(),
    msg="background bottom should be covered by the tile, origin_pos=\{position}, new_pos=\{new_pos}, background_h=\{background.h}",
  )
}

///|
test "HTILED background position" {
  let cloudy_sky_background_json : Json = {
    "a": 255,
    "ani": 0,
    "bS": "grassySoil",
    "cx": 0,
    "cy": 0,
    "f": 0,
    "front": 0,
    "no": 1,
    "rx": -5,
    "ry": -3,
    "type": 4,
    "x": 116,
    "y": -71,
  }
  let nx_cloudy_sky_background : NxBackground = @json.from_json(
    cloudy_sky_background_json,
  )
  let cloudy_sky_background_animation_json : Json = {
    "__h": 579,
    "__w": 1024,
    "origin": [512, 289],
    "z": 0,
    "__i": "assets/map/back/cloud_sky.png",
  }
  let cloudy_sky_background_animation : @resource.NxAnimation = @json.from_json(
    cloudy_sky_background_animation_json,
  )
  let cloudy_sky_background_resource : BackgroundResource = BackgroundResource::new(
    nx_cloudy_sky_background, cloudy_sky_background_animation,
  )
  let cloudy_sky_background : Background = Background::from_resource(
    cloudy_sky_background_resource,
  )
  let cloudy_sky_background_sprite : @sprite.Sprite = new_background_sprite(
    cloudy_sky_background,
    @graphics.BACKGROUND_ZINDEX,
  )
  let count_x = background_axis_sprite_count(cloudy_sky_background, X)
  let count_y = background_axis_sprite_count(cloudy_sky_background, Y)
  let step_x = cloudy_sky_background.tile_step_x.to_double()
  guard cloudy_sky_background_sprite.sprite_type
    is @sprite.Picture({ size, .. }) else {
    fail("tiled background sprite should be a picture")
  }
  assert_eq(count_y, 1, msg="HMOVEA background should only need one row")
  assert_true(
    count_x > 1,
    msg="HMOVEA background should allocate multiple sprites to cover the viewport, count_x=\{count_x}",
  )
  assert_eq(
    size.0.to_int(),
    cloudy_sky_background.tile_step_x,
    msg="default tile step should match the frame width",
  )
  let camera_pos = @selene_math.Vec2D(1972, -268)
  let mut seconds = 60.0
  let delta = 1.0 / 60.0
  let mut y : Double? = None
  while seconds > 0 {
    let backgroud_position = new_background_position(
      cloudy_sky_background, camera_pos, delta,
    )
    assert_true(
      backgroud_position.0 <= camera_pos.0 &&
      backgroud_position.0 + count_x.to_double() * step_x >=
      camera_pos.0 + @graphics.view_size.0.to_double(),
      msg="background sprites should horizontally cover the viewport, background_position=\{backgroud_position}, camera_pos=\{camera_pos}, count_x=\{count_x}, step_x=\{step_x}",
    )
    match y {
      Some(y) =>
        assert_eq(
          backgroud_position.1,
          y,
          msg="HTILED background y should not change, before=\{y}, current=\{backgroud_position.1}",
        )
      None => y = Some(backgroud_position.1)
    }
    seconds -= delta
  }
}

///|
pub struct Backgrounds {
  backs : Array[Background]
  fores : Array[Background]
}

///|
pub struct BackgroundsResource(Array[NxBackground]) derive(Show)

///|
pub impl @json.FromJson for BackgroundsResource with from_json(json, path) {
  @resource.parse_map_based_array(json, path~)
}

///|
pub fn load_backgrounds(
  spec : BackgroundsResource,
  background_animation_sets : Map[
    String,
    Map[BackgroundAnimationPath, @resource.NxAnimation],
  ],
) -> Backgrounds {
  let fronts = Array::new()
  let backgrounds = Array::new()
  for back_spec in spec.0 {
    // TODO: what does empty bS mean?
    if back_spec.bS == "" {
      continue
    }
    let backi = BackgroundResource::new(
      back_spec,
      background_animation_sets[back_spec.bS][BackgroundAnimationPath::from_nx(
        back_spec,
      )],
    )
    backgrounds.push(Background::from_resource(backi))
    fronts.push(back_spec.front)
  }
  let backs = Array::new()
  let fores = Array::new()
  for i, b in backgrounds {
    if fronts[i] {
      fores.push(b)
    } else {
      backs.push(b)
    }
  }
  { backs, fores }
}

///|
fn background_animation_signature(animation : @resource.NxAnimation) -> String {
  let mut key = "blend=\{animation.blend};zigzag=\{animation.zigzag};"
  for frame in animation.frames {
    key += frame.texture.i
    key += "#"
    key += frame.delay.map_or("", fn(delay) { delay.to_string() })
    key += ";"
  }
  key
}

///|
fn background_opacity_animation_spec_from_json(
  json : Json,
) -> BackgroundOpacityAnimationSpec {
  let blend = json is { "blend": Number(1, ..), .. }
  let zigzag = json is { "zigzag": Number(1, ..), .. }
  let frames = if json is { "0": _, .. } {
    let items : Array[BackgroundOpacityFrameSpec] = []
    for i = 0; ; i = i + 1 {
      let frame_json = match json {
        Object(obj) => obj.get(i.to_string()).unwrap_or(null)
        _ => null
      }
      if frame_json == null {
        break
      }
      items.push(background_opacity_frame_spec_from_json(frame_json))
    }
    items
  } else {
    [
      background_opacity_frame_spec_from_json(
        json,
        default_delay_ms=if blend { 2500 } else { 100 },
      ),
    ]
  }
  if frames.is_empty() {
    return default_background_opacity_animation_spec()
  }
  if blend && frames.length() == 1 {
    let frame = frames[0]
    frames.push({
      ..frame,
      start_opacity: frame.end_opacity,
      end_opacity: frame.start_opacity,
    })
  }
  { frames, zigzag }
}

///|
fn background_opacity_frame_spec_from_json(
  json : Json,
  default_delay_ms? : Int = 100,
) -> BackgroundOpacityFrameSpec {
  let (start_opacity, end_opacity) = match json {
    { "a0": Number(a0, ..), "a1": Number(a1, ..), .. } =>
      (a0 / 255.0, a1 / 255.0)
    { "a0": Number(a0, ..), .. } => {
      let start = a0 / 255.0
      (start, 1.0 - start)
    }
    { "a1": Number(a1, ..), .. } => {
      let end = a1 / 255.0
      (1.0 - end, end)
    }
    _ => (1.0, 1.0)
  }
  let delay_ms = match json {
    { "delay": Number(delay, ..), .. } if delay != 0 => delay.to_int()
    _ => default_delay_ms
  }
  { start_opacity, end_opacity, delay_ms }
}

///|
fn default_background_opacity_animation_spec() -> BackgroundOpacityAnimationSpec {
  {
    frames: [{ start_opacity: 1.0, end_opacity: 1.0, delay_ms: 100 }],
    zigzag: false,
  }
}

///|
fn BackgroundOpacityAnimationState::new(
  spec : BackgroundOpacityAnimationSpec,
) -> BackgroundOpacityAnimationState {
  let first = spec.frames[0]
  {
    frames: spec.frames,
    zigzag: spec.zigzag,
    opacity: @utils.Linear::new(first.start_opacity),
    frame: 0,
    frame_step: 1,
    delay_ms: first.delay_ms,
  }
}

///|
fn BackgroundOpacityAnimationState::current_opacity(
  self : BackgroundOpacityAnimationState,
) -> Double {
  self.opacity.get()
}

///|
fn BackgroundOpacityAnimationState::update(
  self : BackgroundOpacityAnimationState,
  timestep_ms : Int,
) -> Unit {
  if timestep_ms <= 0 {
    return
  }
  let frame = self.frames[self.frame]
  let delay_ms = if frame.delay_ms <= 0 { 100 } else { frame.delay_ms }
  let opacity_step = timestep_ms.to_double() *
    (frame.end_opacity - frame.start_opacity) /
    delay_ms.to_double()
  self.opacity.add(opacity_step)
  if self.opacity.get() < 0.0 {
    self.opacity.set(0.0)
  } else if self.opacity.get() > 1.0 {
    self.opacity.set(1.0)
  }
  if timestep_ms >= self.delay_ms {
    let last_frame = self.frames.length() - 1
    let mut next_frame = 0
    if self.zigzag && last_frame > 0 {
      if self.frame_step == 1 && self.frame == last_frame {
        self.frame_step = -self.frame_step
      } else if self.frame_step == -1 && self.frame == 0 {
        self.frame_step = -self.frame_step
      }
      next_frame = self.frame + self.frame_step
    } else if self.frame == last_frame {
      next_frame = 0
    } else {
      next_frame = self.frame + 1
    }
    let delta = timestep_ms - self.delay_ms
    self.frame = next_frame
    self.delay_ms = self.frames[next_frame].delay_ms
    if self.delay_ms > delta {
      self.delay_ms -= delta
    }
    self.opacity.set(self.frames[next_frame].start_opacity)
  } else {
    self.opacity.normalize()
    self.delay_ms -= timestep_ms
  }
}

///|
priv struct BackgroundsContext {
  backgrounds : Backgrounds
  entities : Array[Array[@entity.Entity]]
  mut back_visible : Bool
  mut fore_visible : Bool
  mut debug_index : Int?
  mut dirty : Bool
}

///|
let backgrounds_context : Ref[BackgroundsContext?] = Ref::new(None)

///|
/// 设置游戏场景的背景.
/// 
/// - `backgrounds`: 背景数据.
pub fn set_backgrounds(backgrounds : Backgrounds) -> Unit {
  if backgrounds_context.val is Some(ctx) {
    for entities in ctx.entities {
      for entity in entities {
        entity.destroy()
      }
    }
    ctx.entities.clear()
  }
  let context = {
    backgrounds,
    entities: [],
    back_visible: true,
    fore_visible: true,
    debug_index: None,
    dirty: true,
  }
  backgrounds_context.val = Some(context)
}

///|
pub struct BackgroundVisibilityState {
  back_visible : Bool
  fore_visible : Bool
  debug_index : Int?
  total_layers : Int
} derive(Show)

///|
/// 设置前/后景背景的整体可见性。
/// - `back_visible`: 是否显示背景层。
/// - `fore_visible`: 是否显示前景层。
pub fn set_background_visibility(
  back_visible : Bool,
  fore_visible : Bool,
) -> Unit {
  guard backgrounds_context.val is Some(ctx) else { return }
  if ctx.back_visible == back_visible && ctx.fore_visible == fore_visible {
    return
  }
  ctx.back_visible = back_visible
  ctx.fore_visible = fore_visible
  ctx.dirty = true
}

///|
/// 在调试模式下切换指定背景，只显示某一个背景元素。
/// - `step`: 正数表示下一个背景，负数表示上一个。
pub fn step_background_debug(step : Int) -> Unit {
  guard backgrounds_context.val is Some(ctx) else { return }
  let total = total_background_count(ctx.backgrounds)
  if total == 0 {
    return
  }
  let next = match ctx.debug_index {
    Some(current) => (current + step + total) % total
    None => if step >= 0 { 0 } else { total - 1 }
  }
  ctx.debug_index = Some(next)
  ctx.dirty = true
}

///|
/// 退出背景调试模式，重新显示符合可见性设置的全部背景。
pub fn clear_background_debug() -> Unit {
  guard backgrounds_context.val is Some(ctx) && ctx.debug_index is Some(_) else {
    return
  }
  ctx.debug_index = None
  ctx.dirty = true
}

///|
/// 获取当前背景可见状态，便于调试 UI 显示。
pub fn get_background_visibility_state() -> BackgroundVisibilityState {
  match backgrounds_context.val {
    Some({ back_visible, fore_visible, debug_index, backgrounds, .. }) =>
      {
        back_visible,
        fore_visible,
        debug_index,
        total_layers: total_background_count(backgrounds),
      }
    None =>
      {
        back_visible: true,
        fore_visible: true,
        debug_index: None,
        total_layers: 0,
      }
  }
}

///|
/// 背景系统. 负责初始化背景, 更新背景的位置, 实现视差滚动、循环滚动等效果.
pub fn background_system(delta : Double) -> Unit {
  guard backgrounds_context.val is Some(ctx) else { return }
  let { backgrounds, .. } = ctx
  let expected = expected_background_entity_layout(backgrounds)
  if !background_entity_layout_matches(ctx.entities, expected) {
    for entities in ctx.entities {
      for entity in entities {
        entity.destroy()
      }
    }
    ctx.entities.clear()
    for count in expected {
      let group : Array[@entity.Entity] = []
      for _ in 0..<count {
        group.push(@entity.Entity::new())
      }
      ctx.entities.push(group)
    }
    ctx.dirty = true
  }
  // get camera position (top-left)
  let camera_pos = @camera.get_position()
  if ctx.dirty {
    refresh_background_sprites(ctx, camera_pos)
    ctx.dirty = false
  }
  let mut i = 0
  for b in backgrounds.backs {
    if should_render_background(ctx, i, false) {
      b.update(delta)
      update_background_entities(ctx.entities[i], b, camera_pos, delta)
    }
    i += 1
  }
  for f in backgrounds.fores {
    if should_render_background(ctx, i, true) {
      f.update(delta)
      update_background_entities(ctx.entities[i], f, camera_pos, delta)
    }
    i += 1
  }
}

///|
/// 刷新背景精灵, 设置精灵的可见性。
/// 
/// WORKAROUND: 暂时给每个背景图一个递增的zindex, 模拟顺序渲染的效果, 但会导致 z 值太多了.
fn refresh_background_sprites(
  ctx : BackgroundsContext,
  camera_pos : @selene_math.Vec2D,
) -> Unit {
  let mut idx = 0
  for i, b in ctx.backgrounds.backs {
    let entities = ctx.entities[idx]
    if should_render_background(ctx, idx, false) {
      let z = @graphics.BACKGROUND_ZINDEX + i
      ensure_background_sprites(entities, b, z)
      update_background_entities(entities, b, camera_pos, 0.0)
      set_background_entities_visibility(entities, true)
    } else {
      set_background_entities_visibility(entities, false)
    }
    idx += 1
  }
  for i, f in ctx.backgrounds.fores {
    let entities = ctx.entities[idx]
    if should_render_background(ctx, idx, true) {
      let z = @graphics.FOREGROUND_ZINDEX + i
      ensure_background_sprites(entities, f, z)
      update_background_entities(entities, f, camera_pos, 0.0)
      set_background_entities_visibility(entities, true)
    } else {
      set_background_entities_visibility(entities, false)
    }
    idx += 1
  }
}

///|
fn should_render_background(
  ctx : BackgroundsContext,
  global_index : Int,
  is_foreground : Bool,
) -> Bool {
  let base_visible = if is_foreground {
    ctx.fore_visible
  } else {
    ctx.back_visible
  }
  if not(base_visible) {
    return false
  }
  match ctx.debug_index {
    Some(debug_index) => debug_index == global_index
    None => true
  }
}

///|
fn total_background_count(backgrounds : Backgrounds) -> Int {
  backgrounds.backs.length() + backgrounds.fores.length()
}

///|
fn ensure_background_sprites(
  entities : Array[@entity.Entity],
  background : Background,
  z : Int,
) -> Unit {
  for entity in entities {
    if @sprite.sprites.get(entity) is Some(_) {
      continue
    }
    let sprite = new_background_sprite(background, z)
    @sprite.sprites.set(entity, sprite)
  }
}

///|
fn set_background_entities_visibility(
  entities : Array[@entity.Entity],
  visible : Bool,
) -> Unit {
  for entity in entities {
    if @sprite.sprites.get(entity) is Some(sprite) {
      sprite.visible = visible
    }
  }
}

///|
fn set_background_sprite_alpha(entity : @entity.Entity, alpha : Double) -> Unit {
  if @sprite.sprites.get(entity) is Some(sprite) {
    @sprite.sprites.set(entity, { ..sprite, alpha, })
  }
}

///|
fn background_axis_sprite_count(
  background : Background,
  axis : @selene_math.Axis,
) -> Int {
  let view = if axis == X {
    @graphics.view_size.0
  } else {
    @graphics.view_size.1
  }
  let render = if axis == X {
    background.horizontal_render
  } else {
    background.vertical_render
  }
  match render {
    BackgroundDirRender::Normal(..) => 1
    BackgroundDirRender::Tiled(..) => {
      let raw_step = if axis == X {
        background.tile_step_x
      } else {
        background.tile_step_y
      }
      let step = raw_step.max(1)
      view / step + 3
    }
  }
}

///|
fn background_sprite_count(background : Background) -> Int {
  background_axis_sprite_count(background, X) *
  background_axis_sprite_count(background, Y)
}

///|
fn expected_background_entity_layout(backgrounds : Backgrounds) -> Array[Int] {
  let layout : Array[Int] = []
  for background in backgrounds.backs {
    layout.push(background_sprite_count(background))
  }
  for background in backgrounds.fores {
    layout.push(background_sprite_count(background))
  }
  layout
}

///|
fn background_entity_layout_matches(
  entities : Array[Array[@entity.Entity]],
  expected : Array[Int],
) -> Bool {
  if entities.length() != expected.length() {
    return false
  }
  for i, group in entities {
    if group.length() != expected[i] {
      return false
    }
  }
  true
}

///|
fn update_background_entities(
  entities : Array[@entity.Entity],
  background : Background,
  camera_pos : @selene_math.Vec2D,
  delta : Double,
) -> Unit {
  let base_pos = new_background_position(background, camera_pos, delta)
  let count_x = background_axis_sprite_count(background, X)
  let count_y = background_axis_sprite_count(background, Y)
  let alpha = background.current_opacity()
  let step_x = background.tile_step_x.to_double()
  let step_y = background.tile_step_y.to_double()
  for index, entity in entities {
    let tile_x = index % count_x
    let tile_y = index / count_x
    let pos = @selene_math.Vec2D(
      base_pos.0 + tile_x.to_double() * step_x,
      base_pos.1 + tile_y.to_double() * step_y,
    )
    @position.positions.set(entity, @position.Position(pos))
    set_background_sprite_alpha(entity, alpha)
    if @sprite.sprites.get(entity) is Some(sprite) {
      sprite.visible = tile_x < count_x && tile_y < count_y
    }
  }
}

///|
/// 将一个值限制在一个范围[start, end)内。
/// 
/// - `value`: 要限制的值。
/// - `start`: 范围的起始位置。
/// - `end`: 范围的结束位置。
fn wrap_in_range(value : Double, start~ : Double, end~ : Double) -> Double {
  let width = end - start
  if width <= 0.0 {
    return value
  }
  let mut wrapped = value
  while wrapped >= end {
    wrapped -= width
  }
  while wrapped < start {
    wrapped += width
  }
  wrapped
}
