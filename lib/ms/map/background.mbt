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
} derive(Eq, Compare, Show)

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
pub fn hash(self : BackgroundType) -> Int {
  self.int_value()
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
pub fn Background::load(
  src : @resource.NxNode
) -> @utils.Future[Result[Background, Error]] {
  match src["bS"].get_string() {
    "" => @utils.Future::from_value(Background::from_resource?(src, None))
    bs => {
      let animated = src["ani"].get_bool?().unwrap()
      background_loader
      .load_res([
        bs + ".img",
        if animated {
          "ani"
        } else {
          "back"
        },
        src["no"].get_int?().unwrap().to_string(),
      ])
      .map_exn(fn(res) { Background::from_resource!(src, Some(res)) })
    }
  }
}

///|
fn Background::from_resource(
  src : @resource.NxNode,
  bg_res : @resource.NxNode?
) -> Background! {
  let animation = match bg_res {
    None => @graphics.Animation::default()
    Some(bg_res) => @graphics.Animation::from_resource(bg_res)
  }
  let t = Background::typebyid!(src["type"].as_int!())
  @log.debug({ "type": t, "path": src.path() }, "load background")
  let dim_x = animation.get_dimensions().x
  let dim_y = animation.get_dimensions().y
  if dim_y <= 0 {
    fail!("dim_y <= 0")
  }
  let opacity = src["a"].get_float?().unwrap()
  let flipped = src["f"].get_bool?().unwrap()
  let cx = match src["cx"].get_int?().unwrap() {
    0 => if dim_x > 0 { dim_x } else { 1 }
    cx => cx
  }
  let cy = match src["cy"].get_int?().unwrap() {
    0 => dim_y
    cy => cy
  }
  let vwidth = @constants.constants.get_viewwidth()
  let vheight = @constants.constants.get_viewheight()
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
  let rx = src["rx"].get_float?().unwrap()
  let ry = src["ry"].get_float?().unwrap()
  let move_obj = @physics.MovingObject::default()
  move_obj.set_x(src["x"].get_float?().unwrap())
  move_obj.set_y(src["y"].get_float?().unwrap())
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
pub fn Background::typebyid(id : Int) -> BackgroundType!@utils.UnknownEnum {
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
pub fn draw(
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
          opacity=self.opacity / 255.0,
        ),
        alpha,
      )
      ty += self.cy
    }
    tx += self.cx
  }
}

///|
pub fn update(self : Background) -> Unit {
  self.move_obj.move()
  self.animation.update() |> ignore
}

///|
pub struct Backgrounds {
  backs : Array[Background]
  fores : Array[Background]
}

///|
pub fn load_backgrounds(
  src : @resource.NxNode
) -> @utils.Future[Result[Backgrounds, Error]] {
  let backs = Array::new()
  let fores = Array::new()
  let mut no = 0
  while true {
    let backi = src[no.to_string()]
    match backi.value() {
      Json::Null => break
      { "front": Json::Number(0) } => backs.push(Background::load(backi))
      { "front": Json::Number(_) } => fores.push(Background::load(backi))
      _ => panic()
    }
    no += 1
  }
  @utils.Future::all_of(backs)
  .map(fn(res) { @utils.flatten_ok(res) })
  .combine(@utils.Future::all_of(fores).map(fn(res) { @utils.flatten_ok(res) }))
  .map(fn(res) {
    res.0.bind(fn(backgrounds) {
      res.1.map(fn(foregrounds) { { backs: backgrounds, fores: foregrounds } })
    })
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
