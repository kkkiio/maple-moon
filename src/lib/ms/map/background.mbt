///|
pub(all) enum BackgroundType {
  BG_NORMAL = 0
  HTILED = 1
  VTILED = 2
  TILED = 3
  HMOVEA = 4
  VMOVEA = 5
  HMOVEB = 6
  VMOVEB = 7
} derive(Eq, Compare, Show, ToJson)

///|
pub fn int_value(self : BackgroundType) -> Int = "%identity"

///|
pub fn BackgroundType::from_int(id : Int) -> BackgroundType? {
  let t = match id {
    0 => BackgroundType::BG_NORMAL
    1 => BackgroundType::HTILED
    2 => BackgroundType::VTILED
    3 => BackgroundType::TILED
    4 => BackgroundType::HMOVEA
    5 => BackgroundType::VMOVEA
    6 => BackgroundType::HMOVEB
    7 => BackgroundType::VMOVEB
    _ => return None
  }
  Some(t)
}

///|
struct Background {
  entity : @system.Entity
  animation : @resource.NxAnimation
  position : @position.Position
  t : BackgroundType
  // cx : Int
  // cy : Int
  // rx : Double
  // ry : Double
  // htile : Int
  // vtile : Int
  // opacity : Double
  // flipped : Bool
  // move_obj : @physics.MovingObject
  // woffset : Int
  // hoffset : Int
}

///|
/// example: {"a":255,"ani":0,"bS":"","cx":0,"cy":0,"f":0,"front":0,"no":0,"rx":0,"ry":0,"type":0,"x":0,"y":0}
struct NxBackground {
  a : Int
  ani : Bool
  bS : String // background set
  cx : Int
  cy : Int
  f : Bool
  front : Bool
  no : Int
  rx : Int
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
    t: BackgroundType::from_int(t.to_int()).or_error(
      @json.JsonDecodeError(
        (path.add_key("type"), "unknown background type \{t}"),
      ),
    ),
    x: x.to_int(),
    y: y.to_int(),
  }
}

///|
struct BackgroundResource {
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
  // let vwidth = @config.constants.get_viewwidth()
  // let vheight = @config.constants.get_viewheight()
  // let woffset = vwidth / 2
  // let hoffset = vheight / 2
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
  // let rx = res.rx
  // let ry = res.ry
  // let move_obj = @physics.MovingObject::default()
  // move_obj.set_x(res.x)
  // move_obj.set_y(res.y)
  // match t {
  //   BackgroundType::HMOVEA | BackgroundType::HMOVEB =>
  //     move_obj.hspeed = rx / 16.0
  //   BackgroundType::VMOVEA | BackgroundType::VMOVEB =>
  //     move_obj.vspeed = ry / 16.0
  //   _ => ()
  // }
  // {
  //   animation,
  //   cx,
  //   cy,
  //   rx,
  //   ry,
  //   htile,
  //   vtile,
  //   opacity,
  //   flipped,
  //   move_obj,
  //   woffset,
  //   hoffset,
  // }
  let entity = @system.Entity::new()
  let position = @position.Position(
    @selene_math.Vec2D(res.x.to_double(), res.y.to_double()),
  )
  { entity, animation: res.animation, position, t: res.t }
}

///|
pub fn Background::set_sprites(
  self : Background,
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
  @log.info(
    {
      "position": self.position,
      "size": self.animation.get_size(),
      "z": z,
      "t": self.t,
    },
    "set background sprites",
  )
  let sprite = match self.t {
    BackgroundType::TILED =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(
          world_size,
          self.animation.frames[0].texture.i,
          repeat=Repeat,
        ),
        z,
      )
    _ => @graphics.nx_animation_to_selene_sprite(self.animation, z~)
    // _ => return
  }
  @sprite.sprites.set(self.entity, sprite)
  @position.positions.set(self.entity, self.position)
}

///|
pub fn Background::draw(
  self : Background,
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Unit {

}

///|
pub fn Background::update(self : Background) -> Unit {
  // self.move_obj.do_move()
  // self.animation.update() |> ignore
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
  for back_spec in spec.inner() {
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

// ///|
// pub fn drawbackgrounds(
//   backgrounds : Array[Background],
//   viewx : Double,
//   viewy : Double,
//   alpha : Double,
// ) -> Unit {
//   backgrounds.each(fn(background) { background.draw(viewx, viewy, alpha) })
// }

///|
pub fn drawforegrounds(
  foregrounds : Array[Background],
  viewx : Double,
  viewy : Double,
  alpha : Double,
) -> Unit {
  foregrounds.each(fn(foreground) { foreground.draw(viewx, viewy, alpha) })
}

///|
pub fn update_backgrounds(backgrounds : Backgrounds) -> Unit {
  backgrounds.backs.each(fn(background) { background.update() })
  backgrounds.fores.each(fn(foreground) { foreground.update() })
}
