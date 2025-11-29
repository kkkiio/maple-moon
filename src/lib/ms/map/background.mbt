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
struct Background {
  animation : @resource.NxAnimation
  /// position in world space
  mut position : @selene_math.Vec2D
  t : BackgroundType
  // cx : Int
  // cy : Int
  rx : Double
  ry : Double
  // htile : Int
  // vtile : Int
  // opacity : Double
  // flipped : Bool
}

///|
/// example: {"a":255,"ani":0,"bS":"","cx":0,"cy":0,"f":0,"front":0,"no":0,"rx":0,"ry":0,"type":0,"x":0,"y":0}
struct NxBackground {
  a : Int
  ani : Bool
  /// background set
  bS : String
  cx : Int
  cy : Int
  f : Bool
  front : Bool
  no : Int
  /// parallax ratio of horizontal movement
  rx : Int
  /// parallax ratio of vertical movement
  ry : Int
  t : BackgroundType
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
      "type": Json::Number(t, ..),
      "x": Json::Number(x, ..),
      "y": Json::Number(y, ..),
      ..
    } else {
    raise @json.JsonDecodeError((path, "missing background fields"))
  }
  let front = obj
    .get("front")
    .map_or(false, fn(front) { front is Json::Number(1, ..) })
  let ani = obj.get("ani").map_or(false, fn(ani) { ani is Json::Number(1, ..) })
  {
    a: a.to_int(),
    ani,
    bS,
    cx: cx.to_int(),
    cy: cy.to_int(),
    f: json is { "f": Json::Number(f, ..), .. } && f != 0,
    front,
    no: no.to_int(),
    rx: rx.to_int(),
    ry: ry.to_int(),
    t: BackgroundType::from_int(t.to_int()).unwrap_or_error(
      @json.JsonDecodeError(
        (path.add_key("type"), "unknown background type \{t}"),
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
  background_loader : @resource.AsyncLoader,
  spec : NxBackground,
) -> BackgroundResource {
  let animated = spec.ani
  let bg_res = background_loader.load_res_async([
    spec.bS + ".img",
    if animated {
      "ani"
    } else {
      "back"
    },
    spec.no.to_string(),
  ])
  let animation = @json.from_json(bg_res.value())
  let t = spec.t
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
  let position = @selene_math.Vec2D(res.x.to_double(), res.y.to_double())
  {
    animation: res.animation,
    position,
    t: res.t,
    rx: res.rx.to_double(),
    ry: res.ry.to_double(),
  }
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
  let { animation, position, t, .. } = background
  @log.debug(
    { "size": animation.get_size(), "z": z, "t": t },
    "set background sprites",
  )
  let sprite = match t {
    BackgroundType::TILED => {
      guard animation.frames[0].texture.offset is { x: 0, y: 0 } else {
        @log.error(
          { "offset": animation.frames[0].texture.offset },
          "tiled background in spritesheet is not supported",
        )
        panic()
      }
      let texture = animation.frames[0].texture
      @sprite.Sprite::from_picture(
        @graphics.nx_texture_to_selene_picture(
          texture,
          size=world_size,
          repeat=Repeat,
        ),
        z,
      )
    }
    _ =>
      @sprite.Sprite::from_animation(
        @graphics.nx_animation_to_selene_animation(animation),
        z,
      )
  }
  @sprite.sprites.set(entity, sprite)
  @position.positions.set(entity, @position.Position(position))
}

///|
pub fn update_background_position(
  entity : @entity.Entity,
  background : Background,
) -> Unit {
  // FIXME: 实现循环滚动, 当移动了一个背景的宽度时, 重置位置
  let { t, position, rx, ry, .. } = background
  match t {
    BackgroundType::HMOVEA => {
      // TODO: why divide 16.0?
      let h_speed = rx / 16.0
      background.position = position.update(X, position[X] + h_speed)
    }
    BackgroundType::VMOVEA => {
      // TODO: why divide 16.0?
      let v_speed = ry / 16.0
      background.position = position.update(Y, position[Y] + v_speed)
    }
    _ => ()
  }
  // TODO: 实现视差滚动: 远处移动慢、近处移动快
  let x = if t is BackgroundType::HMOVEA { position[X] } else { position[X] }
  let y = if t is BackgroundType::VMOVEA { position[Y] } else { position[Y] }
  @position.positions.set(entity, @position.Position(@selene_math.Vec2D(x, y)))
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
  background_loader : @resource.AsyncLoader,
  spec : BackgroundsResource,
) -> Backgrounds {
  let fronts = Array::new()
  let backgrounds = Array::new()
  for back_spec in spec.0 {
    // TODO: what does empty bS mean?
    if back_spec.bS == "" {
      continue
    }
    let backi = BackgroundResource::load(background_loader, back_spec)
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
  let times = @config.get_logic_times()
  for _ in 0..<times {
    let mut i = 0
    for b in backgrounds.backs {
      update_background_position(ctx.entities[i], b)
      i += 1
    }
    for f in backgrounds.fores {
      update_background_position(ctx.entities[i], f)
      i += 1
    }
  }
}
