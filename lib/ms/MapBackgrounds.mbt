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

pub let all_background_types : @immut/sorted_map.Map[BackgroundType, Int] = @immut/sorted_map.from_array(
  [
    (BackgroundType::NORMAL, 0),
    (BackgroundType::HTILED, 1),
    (BackgroundType::VTILED, 2),
    (BackgroundType::TILED, 3),
    (BackgroundType::HMOVEA, 4),
    (BackgroundType::VMOVEA, 5),
    (BackgroundType::HMOVEB, 6),
    (BackgroundType::VMOVEB, 7),
  ],
)

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
  let loader = map_loader()
  let animated = src["ani"].get_bool()
  let animation = match src["bS"].get_string() {
    "" => Animation::default()
    bs => {
      let animation_nodepath = make_nodepath(
        [
          "Back",
          bs + ".img",
          if animated {
            "ani"
          } else {
            "back"
          },
          src["no"].get_int().to_string(),
        ],
      )
      println("load background \(animation_nodepath)")
      Animation::from_resource(loader.load_res(animation_nodepath))
    }
  }
  let opacity_ = src["a"].get_float()
  let flipped_ = src["f"].get_bool()
  let cx_ = src["cx"].get_int()
  let cy_ = src["cy"].get_int()
  let rx_ = src["rx"].get_float()
  let ry_ = src["ry"].get_float()
  let move_obj_ = MovingObject::new()
  move_obj_.set_x(src["x"].get_float())
  move_obj_.set_y(src["y"].get_float())
  let t = Background::typebyid(src["type"].get_int())
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

pub fn Background::typebyid(id : Int) -> BackgroundType {
  // if id >= BackgroundType::NORMAL.hash() && id <= BackgroundType::VMOVEB.hash() {
  //   BackgroundType::from_int(id).unwrap()
  // } else {
  //   println("Unknown Background::Type id: [" + id.to_string() + "]")
  //   BackgroundType::NORMAL
  // }
  match
    all_background_types.as_iter().find_first(fn(it) { it.1 == id }).map(
      fn(it) { it.0 },
    ) {
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
  loop src.desc.as_object().bind(fn(it) { it[no.to_string()] }) {
    None => break
    Some(back) => {
      let res = { loader: src.loader, desc: back }
      let front = res["front"].get_bool()
      if front {
        foregrounds_.push(Background::from_resource(res))
      } else {
        backgrounds_.push(Background::from_resource(res))
      }
      no += 1
      continue back.as_object().bind(fn(it) { it[no.to_string()] })
    }
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
