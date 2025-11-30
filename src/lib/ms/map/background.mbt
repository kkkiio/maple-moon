///|
pub(all) enum BackgroundType {
  BG_NORMAL = 0
  HTILED = 1
  VTILED = 2
  TILED = 3
  HMOVEA = 4 // horizontal moving tiled background
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
/// background in a map
pub struct NxBackground {
  a : Int
  /// whether the background is animated
  ani : Bool
  /// background set
  bS : String
  cx : Int
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
  guard json.as_object() is Some(obj) else {
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
  display : BackgroundDisplay
  // cx : Int
  // cy : Int
  // htile : Int
  // vtile : Int
  // opacity : Double
  // flipped : Bool
}

///|
priv enum BackgroundDisplay {
  Normal(position~ : @selene_math.Vec2D, ratio~ : @selene_math.Vec2D)
  Tiled(
    tile_directions~ : (Bool, Bool),
    start~ : @selene_math.Vec2D,
    moving_speed~ : @selene_math.Vec2D
  )
} derive(Show)

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
  let display = match res.t {
    BackgroundType::BG_NORMAL =>
      // Adjust position to be Top-Left relative to world (canceling the origin subtraction in sprite rendering)
      // Only apply this to normal backgrounds (objects).
      BackgroundDisplay::Normal(
        position=@selene_math.Vec2D(res.x.to_double(), res.y.to_double()),
        ratio=@selene_math.Vec2D(res.rx.to_double(), res.ry.to_double()),
      )
    BackgroundType::TILED
    | BackgroundType::HTILED
    | BackgroundType::VTILED
    | BackgroundType::HMOVEA
    | BackgroundType::VMOVEA =>
      // For Tiled backgrounds, (x,y) usually means offset/phase, and shifting the entity position
      // would shrink the render area (clipping the top-left).
      BackgroundDisplay::Tiled(
        tile_directions=(
          res.t
          is (BackgroundType::HTILED
          | BackgroundType::HMOVEA
          | BackgroundType::TILED),
          res.t
          is (BackgroundType::VTILED
          | BackgroundType::VMOVEA
          | BackgroundType::TILED),
        ),
        start=@selene_math.Vec2D(res.x.to_double(), res.y.to_double()),
        // TODO: why divide 16.0?
        moving_speed=@selene_math.Vec2D(
          if res.t is BackgroundType::HMOVEA {
            res.rx.to_double() / 16.0
          } else {
            0.0
          },
          if res.t is BackgroundType::VMOVEA {
            res.ry.to_double() / 16.0
          } else {
            0.0
          },
        ),
      )
  }
  { animation: res.animation, display }
}

///|
pub fn set_background_sprites(
  entity : @entity.Entity,
  background : Background,
  world_size : @selene_math.Vec2D,
  z : Int,
) -> Unit {
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
  let { animation, display } = background
  @log.debug(
    { "size": animation.get_size(), "z": z, "display": display },
    "set background sprites",
  )
  let sprite = match display {
    BackgroundDisplay::Tiled(tile_directions~, start~, ..) => {
      @position.positions.set(entity, @position.Position(start))
      let texture = animation.frames[0].texture
      let repeat = match tile_directions {
        (true, true) => @selene_math.RepeatMode::Repeat
        (true, false) => @selene_math.RepeatMode::RepeatX
        (false, true) => @selene_math.RepeatMode::RepeatY
        (false, false) => @selene_math.RepeatMode::NoRepeat
      }
      @sprite.Sprite::from_picture(
        @graphics.nx_texture_to_selene_picture(
          texture,
          size=world_size +
            @selene_math.Vec2D(
              texture.get_size().0.to_double(),
              texture.get_size().1.to_double(),
            ),
          repeat~,
        ),
        z,
      )
    }
    BackgroundDisplay::Normal(..) =>
      @sprite.Sprite::from_animation(
        @graphics.nx_animation_to_selene_animation(animation),
        z,
      )
  }
  @sprite.sprites.set(entity, sprite)
}

///|
pub fn update_background_position(
  entity : @entity.Entity,
  background : Background,
  camera_pos : @selene_math.Vec2D,
) -> Unit {
  match background.display {
    BackgroundDisplay::Normal(position~, ratio~) => {
      // 实现视差滚动
      // standard parallax: WorldPos = Origin + Camera * (1 - ratio/100)
      let factor = @selene_math.Vec2D(1.0, 1.0) - ratio.scalar_div(100.0)
      let new_pos = position + camera_pos.mul(factor)
      @position.positions.set(entity, @position.Position(new_pos))
    }
    BackgroundDisplay::Tiled(start~, moving_speed~, ..) => {
      // TODO: 平铺背景需要视差滚动吗?
      // circle in [start, start + size)
      let size = background.animation.get_size()
      let pos = @position.positions.get(entity).map_or(start, fn(pos) { pos.0 })
      let x = circle_in_range(
        pos.0 + moving_speed.0,
        start.0,
        start.0 + size.0.to_double(),
      )
      let y = circle_in_range(
        pos.1 + moving_speed.1,
        start.1,
        start.1 + size.1.to_double(),
      )
      @position.positions.set(
        entity,
        @position.Position(@selene_math.Vec2D(x, y)),
      )
    }
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
  world_size : @selene_math.Vec2D
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
/// - `world_size`: 游戏场景大小.
pub fn set_backgrounds(
  backgrounds : Backgrounds,
  world_size : @selene_math.Vec2D,
) -> Unit {
  if backgrounds_context.val is Some(ctx) {
    for entity in ctx.entities {
      entity.destroy()
    }
    ctx.entities.clear()
  }
  let context = {
    backgrounds,
    world_size,
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
pub fn background_system(_delta : Double) -> Unit {
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
  let times = @config.get_logic_times()
  for _ in 0..<times {
    let mut i = 0
    for b in backgrounds.backs {
      if should_render_background(ctx, i, false) {
        update_background_position(ctx.entities[i], b, camera_pos)
      }
      i += 1
    }
    for f in backgrounds.fores {
      if should_render_background(ctx, i, true) {
        update_background_position(ctx.entities[i], f, camera_pos)
      }
      i += 1
    }
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
      ensure_background_sprite(entity, b, ctx.world_size, z)
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
      ensure_background_sprite(entity, f, ctx.world_size, z)
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
  world_size : @selene_math.Vec2D,
  z : Int,
) -> Unit {
  if @sprite.sprites.get(entity) is Some(_) {
    return
  }
  set_background_sprites(entity, background, world_size, z)
}

///|
fn set_sprite_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  if @sprite.sprites.get(entity) is Some(sprite) {
    sprite.visible = visible
  }
}

///|
/// 将一个值限制在一个环形范围内, 超出范围后会循环到另一端。
/// - `value`: 要限制的值。
/// - `start`: 环形的起始位置。
/// - `size`: 环形的大小。
fn circle_in_range(value : Double, start : Double, size : Double) -> Double {
  if value >= start + size {
    value - size
  } else if value < start {
    value + size
  } else {
    value
  }
}
