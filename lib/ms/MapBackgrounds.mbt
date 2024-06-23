pub enum BackgroundType {
  NORMAL
  HTILED
  VTILED
  TILED
  HMOVEA
  VMOVEA
  HMOVEB
  VMOVEB
} derive(Eq, Compare, Debug)

pub fn int_value(self : BackgroundType) -> Int {
  match self {
    BackgroundType::NORMAL => 0
    BackgroundType::HTILED => 1
    BackgroundType::VTILED => 2
    BackgroundType::TILED => 3
    BackgroundType::HMOVEA => 4
    BackgroundType::VMOVEA => 5
    BackgroundType::HMOVEB => 6
    BackgroundType::VMOVEB => 7
  }
}

pub fn hash(self : BackgroundType) -> Int {
  self.int_value()
}

struct Background {
  mut animation : Animation
  mut cx : Int
  mut cy : Int
  mut rx : Double
  mut ry : Double
  mut htile : Int
  mut vtile : Int
  mut opacity : Double
  mut flipped : Bool
  mut move_obj : MovingObject
}

let vwidth : Int = @Constants.constants.viewWidth

let vheight : Int = @Constants.constants.viewHeight

let woffset : Int = vwidth / 2

let hoffset : Int = vheight / 2

pub fn Background::from_resource(src : NxNode) -> Background {
  let srcpath = src.path
  println("load background \(srcpath)")
  let loader = map_loader()
  let animated = src["ani"].get_bool().unwrap()
  let animation = match src["bS"].get_string() {
    "" => Animation::default()
    bs =>
      Animation::from_resource(
        loader.load_res(
          [
            "Back",
            bs + ".img",
            if animated {
              "ani"
            } else {
              "back"
            },
            src["no"].get_int().unwrap().to_string(),
          ],
        ),
      )
  }
  let opacity_ = src["a"].get_float().unwrap()
  let flipped_ = src["f"].get_bool().unwrap()
  let cx_ = src["cx"].get_int().unwrap()
  let cy_ = src["cy"].get_int().unwrap()
  let rx_ = src["rx"].get_float().unwrap()
  let ry_ = src["ry"].get_float().unwrap()
  let move_obj_ = MovingObject::default()
  move_obj_.set_x(src["x"].get_float().unwrap())
  move_obj_.set_y(src["y"].get_float().unwrap())
  let t = Background::typebyid(src["type"].get_int().unwrap())
  let background = {
    animation,
    cx: cx_,
    cy: cy_,
    rx: rx_,
    ry: ry_,
    htile: 1,
    vtile: 1,
    opacity: opacity_,
    flipped: flipped_,
    move_obj: move_obj_,
  }
  background.settype(t)
  background
}

let int_background_type_map : @immut/sorted_map.Map[Int, BackgroundType] = @immut/sorted_map.from_array(
  [
    (0, BackgroundType::NORMAL),
    (1, BackgroundType::HTILED),
    (2, BackgroundType::VTILED),
    (3, BackgroundType::TILED),
    (4, BackgroundType::HMOVEA),
    (5, BackgroundType::VMOVEA),
    (6, BackgroundType::HMOVEB),
    (7, BackgroundType::VMOVEB),
  ],
)

pub fn Background::typebyid(id : Int) -> BackgroundType {
  match int_background_type_map[id] {
    Some(t) => t
    None => {
      println("Unknown Background::Type id: [" + id.to_string() + "]")
      BackgroundType::NORMAL
    }
  }
}

pub fn Background::settype(self : Background, t : BackgroundType) -> Unit {
  let dim_x = self.animation.get_dimensions().x
  let dim_y = self.animation.get_dimensions().y
  if self.cx == 0 {
    self.cx = if dim_x > 0 { dim_x } else { 1 }
  }
  if self.cy == 0 {
    self.cy = if dim_y > 0 { dim_y } else { 1 }
  }
  self.htile = 1
  self.vtile = 1
  match t {
    BackgroundType::HTILED | BackgroundType::HMOVEA =>
      self.htile = vwidth / self.cx + 3
    BackgroundType::VTILED | BackgroundType::VMOVEA =>
      self.vtile = vheight / self.cy + 3
    BackgroundType::TILED | BackgroundType::HMOVEB | BackgroundType::VMOVEB => {
      self.htile = vwidth / self.cx + 3
      self.vtile = vheight / self.cy + 3
    }
    _ => ()
  }
  match t {
    BackgroundType::HMOVEA | BackgroundType::HMOVEB =>
      self.move_obj.hspeed = self.rx / 16.0
    BackgroundType::VMOVEA | BackgroundType::VMOVEB =>
      self.move_obj.vspeed = self.ry / 16.0
    _ => ()
  }
}

pub fn Background::draw(
  self : Background,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let mut x = if self.move_obj.hmobile() {
    self.move_obj.get_absolute_x(viewx, alpha)
  } else {
    let shift_x = self.rx * (woffset.to_double() - viewx) / 100.0 + woffset.to_double()
    self.move_obj.get_absolute_x(shift_x, alpha)
  }
  let mut y = if self.move_obj.vmobile() {
    self.move_obj.get_absolute_y(viewy, alpha)
  } else {
    let shift_y = self.ry * (hoffset.to_double() - viewy) / 100.0 + hoffset.to_double()
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
        DrawArgument::new14(
          { x: ix + tx, y: iy + ty },
          self.flipped,
          self.opacity / 255.0,
        ),
        alpha,
      )
      ty += self.cy
    }
    tx += self.cx
  }
}

pub fn Background::update(self : Background) -> Unit {
  self.move_obj.move()
  self.animation.update() |> ignore
}

pub struct MapBackgrounds {
  backgrounds : Array[Background]
  foregrounds : Array[Background]
  black : Bool
}

pub fn MapBackgrounds::new(src : NxNode) -> MapBackgrounds {
  let backgrounds_ = Array::new()
  let foregrounds_ = Array::new()
  let mut no = 0
  while true {
    let back = src[no.to_string()]
    if back.is_null() {
      break
    }
    let front = back["front"].get_bool().unwrap()
    if front {
      foregrounds_.push(Background::from_resource(back))
    } else {
      backgrounds_.push(Background::from_resource(back))
    }
    no += 1
  }
  let black = src["0"]["bS"].get_string().length() <= 0
  { backgrounds: backgrounds_, foregrounds: foregrounds_, black }
}

pub fn MapBackgrounds::default() -> MapBackgrounds {
  { backgrounds: Array::new(), foregrounds: Array::new(), black: false }
}

pub fn MapBackgrounds::drawbackgrounds(
  self : MapBackgrounds,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if self.black {
    GraphicsGL::get().draw_screen_fill(0.0, 0.0, 0.0, 1.0)
  }
  self.backgrounds.iter(fn(background) { background.draw(viewx, viewy, alpha) })
}

pub fn MapBackgrounds::drawforegrounds(
  self : MapBackgrounds,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.foregrounds.iter(fn(foreground) { foreground.draw(viewx, viewy, alpha) })
}

pub fn MapBackgrounds::update(self : MapBackgrounds) -> Unit {
  self.backgrounds.iter(fn(background) { background.update() })
  self.foregrounds.iter(fn(foreground) { foreground.update() })
}
