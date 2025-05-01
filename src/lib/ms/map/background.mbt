///|
pub(all) enum BackgroundType {
  BG_NORMAL
  HTILED
  VTILED
  TILED
  HMOVEA
  VMOVEA
  HMOVEB
  VMOVEB
} derive(Eq, Compare, Show, ToJson)

///|
pub fn int_value(self : BackgroundType) -> Int {
  match self {
    BackgroundType::BG_NORMAL => 0
    BackgroundType::HTILED => 1
    BackgroundType::VTILED => 2
    BackgroundType::TILED => 3
    BackgroundType::HMOVEA => 4
    BackgroundType::VMOVEA => 5
    BackgroundType::HMOVEB => 6
    BackgroundType::VMOVEB => 7
  }
}

///|
pub fn BackgroundType::from_int(id : Int) -> BackgroundType!@utils.UnknownEnum {
  match id {
    0 => BackgroundType::BG_NORMAL
    1 => BackgroundType::HTILED
    2 => BackgroundType::VTILED
    3 => BackgroundType::TILED
    4 => BackgroundType::HMOVEA
    5 => BackgroundType::VMOVEA
    6 => BackgroundType::HMOVEB
    7 => BackgroundType::VMOVEB
    _ => raise @utils.UnknownEnum(id)
  }
}

///|
struct Background {
  animation : @graphics.Animation
  cx : Int
  cy : Int
  rx : Double
  ry : Double
  htile : Int
  vtile : Int
  opacity : Double
  flipped : Bool
  move_obj : @physics.MovingObject
  woffset : Int
  hoffset : Int
}

///| 
/// example: {"a":255,"ani":0,"bS":"","cx":0,"cy":0,"f":0,"front":0,"no":0,"rx":0,"ry":0,"type":0,"x":0,"y":0}
struct BackgroundSpec {
  a : Int
  ani : Bool
  bS : String
  cx : Int
  cy : Int
  f : Bool
  front : Bool
  no : Int
  rx : Int
  ry : Int
  type_ : BackgroundType
  x : Int
  y : Int
} derive(ToJson)

///|
pub impl @json.FromJson for BackgroundSpec with from_json(json, path) {
  match json {
    {
      "a": Json::Number(a),
      "ani": Json::Number(ani),
      "bS": Json::String(bS),
      "cx": Json::Number(cx),
      "cy": Json::Number(cy),
      "front": Json::Number(front),
      "no": Json::Number(no),
      "rx": Json::Number(rx),
      "ry": Json::Number(ry),
      "type": Json::Number(type_),
      "x": Json::Number(x),
      "y": Json::Number(y),
      ..
    } =>
      {
        a: a.to_int(),
        ani: ani.to_int() != 0,
        bS,
        cx: cx.to_int(),
        cy: cy.to_int(),
        f: json is { "f": Json::Number(f), .. } && f != 0,
        front: front.to_int() != 0,
        no: no.to_int(),
        rx: rx.to_int(),
        ry: ry.to_int(),
        type_: try {
          BackgroundType::from_int!(type_.to_int())
        } catch {
          e =>
            raise @json.JsonDecodeError((path.add_key("type"), e.to_string()))
        },
        x: x.to_int(),
        y: y.to_int(),
      }
    _ => raise @json.JsonDecodeError((path, "expected object"))
  }
}

///|
struct BackgroundResource {
  animation : @graphics.Animation
  t : BackgroundType
  x : Double
  y : Double
  cx : Int
  cy : Int
  rx : Double
  ry : Double
  opacity : Double
  flipped : Bool
}

///|
pub fn BackgroundResource::load(
  background_loader : @resource.AsyncLoader,
  spec : BackgroundSpec
) -> @utils.Future[BackgroundResource] {
  let animated = spec.ani
  background_loader
  .load_res([
    spec.bS + ".img",
    if animated {
      "ani"
    } else {
      "back"
    },
    spec.no.to_string(),
  ])
  .map(fn(bg_res) -> BackgroundResource {
    let animation = @graphics.Animation::from_resource(bg_res)
    let t = spec.type_
    let opacity = spec.a.to_double() / 255.0
    let flipped = spec.f
    let cx = spec.cx
    let cy = spec.cy
    let rx = spec.rx.to_double()
    let ry = spec.ry.to_double()
    let x = spec.x.to_double()
    let y = spec.y.to_double()
    { animation, t, x, y, cx, cy, rx, ry, opacity, flipped }
  })
}

///|
fn Background::from_resource(res : BackgroundResource) -> Background {
  let animation = res.animation
  let t = res.t
  let dim_x = animation.get_dimensions().x
  let dim_y = animation.get_dimensions().y
  if dim_y <= 0 {
    panic()
  }
  let opacity = res.opacity
  let flipped = res.flipped
  let cx = match res.cx {
    0 => if dim_x > 0 { dim_x } else { 1 }
    cx => cx
  }
  let cy = match res.cy {
    0 => dim_y
    cy => cy
  }
  let vwidth = @config.constants.get_viewwidth()
  let vheight = @config.constants.get_viewheight()
  let woffset = vwidth / 2
  let hoffset = vheight / 2
  let htile = match t {
    BackgroundType::HTILED
    | BackgroundType::HMOVEA
    | BackgroundType::TILED
    | BackgroundType::HMOVEB
    | BackgroundType::VMOVEB => vwidth / cx + 3
    _ => 1
  }
  let vtile = match t {
    BackgroundType::VTILED
    | BackgroundType::VMOVEA
    | BackgroundType::TILED
    | BackgroundType::HMOVEB
    | BackgroundType::VMOVEB => vheight / cy + 3
    _ => 1
  }
  let rx = res.rx
  let ry = res.ry
  let move_obj = @physics.MovingObject::default()
  move_obj.set_x(res.x)
  move_obj.set_y(res.y)
  match t {
    BackgroundType::HMOVEA | BackgroundType::HMOVEB =>
      move_obj.hspeed = rx / 16.0
    BackgroundType::VMOVEA | BackgroundType::VMOVEB =>
      move_obj.vspeed = ry / 16.0
    _ => ()
  }
  {
    animation,
    cx,
    cy,
    rx,
    ry,
    htile,
    vtile,
    opacity,
    flipped,
    move_obj,
    woffset,
    hoffset,
  }
}

///|
pub fn Background::draw(
  self : Background,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let mut x = if self.move_obj.hmobile() {
    self.move_obj.get_absolute_x(viewx, alpha)
  } else {
    let shift_x = self.rx * (self.woffset.to_double() - viewx) / 100.0 +
      self.woffset.to_double()
    self.move_obj.get_absolute_x(shift_x, alpha)
  }
  let mut y = if self.move_obj.vmobile() {
    self.move_obj.get_absolute_y(viewy, alpha)
  } else {
    let shift_y = self.ry * (self.hoffset.to_double() - viewy) / 100.0 +
      self.hoffset.to_double()
    self.move_obj.get_absolute_y(shift_y, alpha)
  }
  if self.htile > 1 {
    while x > 0 {
      x -= self.cx
    }
    while x < -self.cx {
      x += self.cx
    }
  }
  if self.vtile > 1 {
    while y > 0 {
      y -= self.cy
    }
    while y < -self.cy {
      y += self.cy
    }
  }
  let ix = x
  let iy = y
  let tw = self.cx * self.htile
  let th = self.cy * self.vtile
  let mut tx = 0
  while tx < tw {
    let mut ty = 0
    while ty < th {
      self.animation.draw(
        @graphics.DrawArgument::new(
          pos={ x: ix + tx, y: iy + ty },
          flip=self.flipped,
          opacity=self.opacity,
        ),
        alpha,
      )
      ty += self.cy
    }
    tx += self.cx
  }
}

///|
pub fn Background::update(self : Background) -> Unit {
  self.move_obj.do_move()
  self.animation.update() |> ignore
}

///|
pub struct Backgrounds {
  backs : Array[Background]
  fores : Array[Background]
}

///|
type BackgroundsSpec Array[BackgroundSpec] derive(ToJson)

///|
pub impl @json.FromJson for BackgroundsSpec with from_json(json, path) {
  guard json.as_object() is Some(obj) else {
    raise @json.JsonDecodeError((path, "expected object"))
  }
  let specs = Array::new()
  let mut i = 0
  while true {
    let key = i.to_string()
    guard obj.get(key) is Some(backi) else { break }
    let spec : BackgroundSpec = @json.from_json!(backi, path=path.add_key(key))
    specs.push(spec)
    i += 1
  }
  specs
}

///|
pub fn load_backgrounds(
  background_loader : @resource.AsyncLoader,
  spec : BackgroundsSpec
) -> @utils.Future[Backgrounds] {
  let fronts = Array::new()
  let back_futs = Array::new()
  for back_spec in spec._ {
    // TODO: what does empty bS mean?
    if back_spec.bS == "" {
      continue
    }
    let backi_fut = BackgroundResource::load(background_loader, back_spec).map(fn(
      res
    ) {
      Background::from_resource(res)
    })
    fronts.push(back_spec.front)
    back_futs.push(backi_fut)
  }
  @utils.Future::all_of(back_futs).map(fn(
    backgrounds : Array[Background]
  ) -> Backgrounds {
    let backs = Array::new()
    let fores = Array::new()
    for i, front in fronts.iter2() {
      if front {
        fores.push(backgrounds[i])
      } else {
        backs.push(backgrounds[i])
      }
    }
    { backs, fores }
  })
}

///|
pub fn drawbackgrounds(
  backgrounds : Array[Background],
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  backgrounds.each(fn(background) { background.draw(viewx, viewy, alpha) })
}

///|
pub fn drawforegrounds(
  foregrounds : Array[Background],
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  foregrounds.each(fn(foreground) { foreground.draw(viewx, viewy, alpha) })
}

///|
pub fn update_backgrounds(backgrounds : Backgrounds) -> Unit {
  backgrounds.backs.each(fn(background) { background.update() })
  backgrounds.fores.each(fn(foreground) { foreground.update() })
}

///|
let background_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "background",
)
