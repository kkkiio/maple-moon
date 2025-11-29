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
struct NxBackground {
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
      #|{a: 255, ani: false, bS: "", cx: 0, cy: 0, f: false, front: false, no: 0, rx: 0, ry: 0, t: BG_NORMAL, x: 0, y: 0}
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
pub async fn BackgroundResource::load(
  bs_loader : @resource.AsyncLoader,
  spec : NxBackground,
) -> BackgroundResource {
  let animated = spec.ani
  let bg_res = bs_loader.load_res_async([
    spec.bS + ".img",
    if animated {
      "ani"
    } else {
      "back"
    },
    spec.no.to_string(),
  ])
  let animation = @json.from_json(bg_res.value())
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
    offset~ : @selene_math.Vec2D,
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
        offset=@selene_math.Vec2D(res.x.to_double(), res.y.to_double()),
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
    BackgroundDisplay::Tiled(tile_directions~, offset~, ..) => {
      @position.positions.set(entity, @position.Position(offset))
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
          size=world_size,
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
  camera_center : @selene_math.Vec2D,
) -> Unit {
  match background.display {
    BackgroundDisplay::Normal(position~, ratio~) => {
      // 实现视差滚动: 远处移动慢、近处移动快
      // Parallax formula: pos' = pos + (pos - center) * rate / 100
      let new_pos = (position - camera_center).mul(ratio.scalar_div(100.0))
      @position.positions.set(entity, @position.Position(new_pos))
    }
    BackgroundDisplay::Tiled(offset~, moving_speed~, ..) => {
      // 平铺背景不需要视差滚动
      // FIXME: 实现循环滚动, 当移动了一个背景的宽度时, 重置位置
      let new_pos = @position.positions
        .get(entity)
        .map_or(offset, fn(pos) { pos.0 }) +
        moving_speed
      @position.positions.set(entity, @position.Position(new_pos))
    }
  }
}

///|
pub struct Backgrounds {
  backs : Array[Background]
  fores : Array[Background]
}

///|
struct BackgroundsResource(Array[NxBackground]) derive(Show)

///|
pub impl @json.FromJson for BackgroundsResource with from_json(json, path) {
  @resource.parse_map_based_array(json, path~)
}

///|
pub async fn load_backgrounds(
  bs_loader : @resource.AsyncLoader,
  spec : BackgroundsResource,
) -> Backgrounds {
  let fronts = Array::new()
  let backgrounds = Array::new()
  for back_spec in spec.0 {
    // TODO: what does empty bS mean?
    if back_spec.bS == "" {
      continue
    }
    let backi = BackgroundResource::load(bs_loader, back_spec)
    backgrounds.push(Background::from_resource(backi))
    fronts.push(back_spec.front)
  }
  let backs = Array::new()
  let fores = Array::new()
  for i, front in fronts {
    if front {
      fores.push(backgrounds[i])
    } else {
      backs.push(backgrounds[i])
    }
  }
  { backs, fores }
}

///|
priv struct BackgroundsContext {
  backgrounds : Backgrounds
  world_size : @selene_math.Vec2D
  entities : Array[@entity.Entity]
}

///|
let backgrounds_context : Ref[BackgroundsContext?] = Ref::new(None)

///|
pub fn set_backgrounds(
  backgrounds : Backgrounds,
  world_size : @selene_math.Vec2D,
) -> Unit {
  if backgrounds_context.val is Some({ entities, .. }) {
    for entity in entities {
      entity.destroy()
    }
    entities.clear()
  }
  let context = { backgrounds, world_size, entities: [] }
  backgrounds_context.val = Some(context)
}

///|
/// 背景系统. 负责初始化背景, 更新背景的位置, 实现视差滚动、循环滚动等效果.
pub fn background_system(_delta : Double) -> Unit {
  guard backgrounds_context.val is Some(ctx) else { return }
  let { backgrounds, world_size, .. } = ctx
  if ctx.entities.length() !=
    backgrounds.backs.length() + backgrounds.fores.length() {
    ctx.entities.clear()
    for i, b in backgrounds.backs {
      let z = @graphics.BACKGROUND_ZINDEX + i // WORKAROUND: 暂时给每个背景图一个递增的zindex, 模拟顺序渲染的效果
      let entity = @entity.Entity::new()
      set_background_sprites(entity, b, world_size, z)
      ctx.entities.push(entity)
    }
    for i, f in backgrounds.fores {
      let z = @graphics.FOREGROUND_ZINDEX + i // WORKAROUND: 暂时给每个前景图一个递增的zindex, 模拟顺序渲染的效果
      let entity = @entity.Entity::new()
      set_background_sprites(entity, f, world_size, z)
      ctx.entities.push(entity)
    }
  }
  // get camera position (top-left)
  let camera_pos = @camera.get_position()
  let zoom = @backend.get_zoom()
  let viewport_size = @backend.get_canvas_size() * Vec2D(1 / zoom, 1 / zoom)
  let camera_center = (camera_pos + viewport_size).scalar_div(2)
  let times = @config.get_logic_times()
  for _ in 0..<times {
    let mut i = 0
    for b in backgrounds.backs {
      update_background_position(ctx.entities[i], b, camera_center)
      i += 1
    }
    for f in backgrounds.fores {
      update_background_position(ctx.entities[i], f, camera_center)
      i += 1
    }
  }
}
