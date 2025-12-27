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
  /// frame width
  cx : Int
  /// frame height
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
  cx : Int
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
  let bg_res = bs_loader.load_res_async([
    background_set_name + ".img",
    if animated {
      "ani"
    } else {
      "back"
    },
    no.to_string(),
  ])
  @json.from_json(bg_res.value())
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
  // let animation = res.animation
  // let t = res.t
  // let dim_x = animation.get_dimensions().x
  // let dim_y = animation.get_dimensions().y
  // if dim_y <= 0 {
  //   panic()
  // }
  // let opacity = res.opacity
  // let flipped = res.flipped
  // let cx = match res.cx {
  //   0 => if dim_x > 0 { dim_x } else { 1 }
  //   cx => cx
  // }
  // let cy = match res.cy {
  //   0 => dim_y
  //   cy => cy
  // }
  // let htile = match t {
  //   BackgroundType::HTILED
  //   | BackgroundType::HMOVEA
  //   | BackgroundType::TILED
  //   | BackgroundType::HMOVEB
  //   | BackgroundType::VMOVEB => vwidth / cx + 3
  //   _ => 1
  // }
  // let vtile = match t {
  //   BackgroundType::VTILED
  //   | BackgroundType::VMOVEA
  //   | BackgroundType::TILED
  //   | BackgroundType::HMOVEB
  //   | BackgroundType::VMOVEB => vheight / cy + 3
  //   _ => 1
  // }
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
      BackgroundDirRender::Tiled(moving_speed~, offset=0.0)
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
      BackgroundDirRender::Tiled(moving_speed~, offset=0.0)
    }
  }
  { animation: res.animation, horizontal_render, vertical_render }
}

///|
fn new_background_sprite(background : Background, z : Int) -> @sprite.Sprite {
  // let mut x = if self.move_obj.hmobile() {
  //   self.move_obj.get_absolute_x(viewx, alpha)
  // } else {
  //   let shift_x = self.rx * (self.woffset.to_double() - viewx) / 100.0 +
  //     self.woffset.to_double()
  //   self.move_obj.get_absolute_x(shift_x, alpha)
  // }
  // let mut y = if self.move_obj.vmobile() {
  //   self.move_obj.get_absolute_y(viewy, alpha)
  // } else {
  //   let shift_y = self.ry * (self.hoffset.to_double() - viewy) / 100.0 +
  //     self.hoffset.to_double()
  //   self.move_obj.get_absolute_y(shift_y, alpha)
  // }
  // if self.htile > 1 {
  //   while x > 0 {
  //     x -= self.cx
  //   }
  //   while x < -self.cx {
  //     x += self.cx
  //   }
  // }
  // if self.vtile > 1 {
  //   while y > 0 {
  //     y -= self.cy
  //   }
  //   while y < -self.cy {
  //     y += self.cy
  //   }
  // }
  // let ix = x
  // let iy = y
  // let tw = self.cx * self.htile
  // let th = self.cy * self.vtile
  // let mut tx = 0
  // while tx < tw {
  //   let mut ty = 0
  //   while ty < th {
  //     self.animation.draw(
  //       @graphics.DrawArgument::new(
  //         pos={ x: ix + tx, y: iy + ty },
  //         flip=self.flipped,
  //         opacity=self.opacity,
  //       ),
  //       alpha,
  //     )
  //     ty += self.cy
  //   }
  //   tx += self.cx
  // }
  let { animation, horizontal_render, vertical_render } = background
  let texture = animation.frames[0].texture
  let repeat : @selene_math.RepeatMode = match
    (horizontal_render, vertical_render) {
    (BackgroundDirRender::Normal(..), BackgroundDirRender::Normal(..)) =>
      NoRepeat
    (BackgroundDirRender::Tiled(..), BackgroundDirRender::Normal(..)) => RepeatX
    (BackgroundDirRender::Normal(..), BackgroundDirRender::Tiled(..)) => RepeatY
    (BackgroundDirRender::Tiled(..), BackgroundDirRender::Tiled(..)) => Repeat
  }
  let w = if horizontal_render is BackgroundDirRender::Tiled(..) {
    @graphics.view_size.0 + texture.w * 3
  } else {
    texture.w
  }
  let h = if vertical_render is BackgroundDirRender::Tiled(..) {
    @graphics.view_size.1 + texture.h * 3
  } else {
    texture.h
  }
  let size = @selene_math.Vec2D(w.to_double(), h.to_double())
  @sprite.Sprite::from_picture(
    nx_texture_to_selene_picture(texture, size~, repeat~),
    z,
  )
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
      // TODO: support get cx from background resource
      let cx = background.animation.get_size().0
      let x = move_along_axis(tiled.offset, moving_speed, delta, cx.to_double())
      tiled.offset = x
      camera_pos[X] + tiled.offset
    }
  }
  let y = match background.vertical_render {
    BackgroundDirRender::Normal(offset~, parallax_ratio~) =>
      parallax_shift(offset, parallax_ratio, Y, camera_pos, view_size)
    BackgroundDirRender::Tiled(moving_speed~, ..) as tiled => {
      // TODO: support get cy from background resource
      let cy = background.animation.get_size().1
      let y = move_along_axis(tiled.offset, moving_speed, delta, cy.to_double())
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
  guard cloudy_sky_background_sprite.sprite_type
    is @sprite.Picture({ size, repeat: RepeatX, .. }) else {
    fail("HTILED background sprite should be a picture with RepeatX")
  }
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
      backgroud_position.0 + @graphics.view_size.0.to_double() + size.0 >=
      camera_pos.0 + @graphics.view_size.0.to_double(),
      msg="background should horizontally cover the viewport, background_position=\{backgroud_position}, camera_pos=\{camera_pos}",
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
priv struct BackgroundsContext {
  backgrounds : Backgrounds
  entities : Array[@entity.Entity]
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
    for entity in ctx.entities {
      entity.destroy()
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
  let expected = total_background_count(backgrounds)
  if ctx.entities.length() != expected {
    for entity in ctx.entities {
      entity.destroy()
    }
    ctx.entities.clear()
    for _ in 0..<expected {
      ctx.entities.push(@entity.Entity::new())
    }
    ctx.dirty = true
  }
  if ctx.dirty {
    refresh_background_sprites(ctx)
    ctx.dirty = false
  }
  // get camera position (top-left)
  let camera_pos = @camera.get_position()
  let mut i = 0
  for b in backgrounds.backs {
    if should_render_background(ctx, i, false) {
      let pos = new_background_position(b, camera_pos, delta)
      @position.positions.set(ctx.entities[i], @position.Position(pos))
    }
    i += 1
  }
  for f in backgrounds.fores {
    if should_render_background(ctx, i, true) {
      let pos = new_background_position(f, camera_pos, delta)
      @position.positions.set(ctx.entities[i], @position.Position(pos))
    }
    i += 1
  }
}

///|
/// 刷新背景精灵, 设置精灵的可见性。
/// 
/// WORKAROUND: 暂时给每个背景图一个递增的zindex, 模拟顺序渲染的效果, 但会导致 z 值太多了.
fn refresh_background_sprites(ctx : BackgroundsContext) -> Unit {
  let mut idx = 0
  for i, b in ctx.backgrounds.backs {
    let entity = ctx.entities[idx]
    if should_render_background(ctx, idx, false) {
      let z = @graphics.BACKGROUND_ZINDEX + i
      ensure_background_sprite(entity, b, z)
      set_sprite_visibility(entity, true)
    } else {
      set_sprite_visibility(entity, false)
    }
    idx += 1
  }
  for i, f in ctx.backgrounds.fores {
    let entity = ctx.entities[idx]
    if should_render_background(ctx, idx, true) {
      let z = @graphics.FOREGROUND_ZINDEX + i
      ensure_background_sprite(entity, f, z)
      set_sprite_visibility(entity, true)
    } else {
      set_sprite_visibility(entity, false)
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
fn ensure_background_sprite(
  entity : @entity.Entity,
  background : Background,
  z : Int,
) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  let sprite = new_background_sprite(background, z)
  @sprite.sprites.set(entity, sprite)
}

///|
fn set_sprite_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  if @sprite.sprites.get(entity) is Some(sprite) {
    sprite.visible = visible
  }
}

///|
/// 将一个值限制在一个范围[start, end)内。
/// 
/// - `value`: 要限制的值。
/// - `start`: 范围的起始位置。
/// - `end`: 范围的结束位置。
fn wrap_in_range(value : Double, start~ : Double, end~ : Double) -> Double {
  if value >= end {
    value - end
  } else if value < start {
    value + end
  } else {
    value
  }
}
