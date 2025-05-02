///|
typealias Point[T] = @struct.Point[T]

///|
typealias Color = @struct.Color

///|
typealias Rectangle[T] = @struct.Rectangle[T]

///|
pub(all) struct DrawArgument {
  pos : Point[Int]
  center : Point[Int]
  stretch : Point[Int]
  xscale : Double
  yscale : Double
  angle : Double
  color : Color
} derive(Show, ToJson)

///|
pub impl Default for DrawArgument with default() -> DrawArgument {
  DrawArgument::new()
}

///|
pub fn DrawArgument::from_xy(x : Int, y : Int) -> DrawArgument {
  DrawArgument::new(pos={ x, y })
}

///|
pub fn DrawArgument::new(
  pos~ : Point[Int] = @struct.Point::default(),
  flip~ : Bool = false,
  opacity~ : Double = 1.0,
  angle~ : Double = 0.0
) -> DrawArgument {
  DrawArgument::new16(
    pos,
    pos,
    { x: 0, y: 0 },
    if flip {
      -1.0
    } else {
      1.0
    },
    1.0,
    opacity,
    angle,
  )
}

///|
pub fn DrawArgument::new_ex(
  pos~ : Point[Int] = @struct.Point::default(),
  stretch~ : Point[Int] = @struct.Point::default(),
  opacity~ : Double = 1.0,
  angle~ : Double = 0.0
) -> DrawArgument {
  DrawArgument::new16(pos, pos, stretch, 1.0, 1.0, opacity, angle)
}

///|
pub fn DrawArgument::new_scale(
  position~ : Point[Int] = @struct.Point::default(),
  scale~ : Double = 1.0
) -> DrawArgument {
  DrawArgument::new10(position, position, scale, scale, 1.0)
}

///|
pub fn DrawArgument::from_pos_and_stretch(
  position : Point[Int],
  stretch : Point[Int]
) -> DrawArgument {
  DrawArgument::new16(position, position, stretch, 1.0, 1.0, 1.0, 0.0)
}

///|
pub fn DrawArgument::new6(
  angle : Double,
  position : Point[Int],
  opacity : Double
) -> DrawArgument {
  DrawArgument::new15(angle, position, false, opacity)
}

///|
pub fn DrawArgument::new7(
  position : Point[Int],
  opacity : Double
) -> DrawArgument {
  DrawArgument::new14(position, false, opacity~)
}

///|
pub fn DrawArgument::from_point_and_color(
  position : Point[Int],
  color : Color
) -> DrawArgument {
  DrawArgument::new17(position, position, { x: 0, y: 0 }, 1.0, 1.0, color, 0.0)
}

///|
pub fn DrawArgument::new9(
  position : Point[Int],
  flip : Bool,
  center : Point[Int]
) -> DrawArgument {
  DrawArgument::new10(position, center, if flip { -1.0 } else { 1.0 }, 1.0, 1.0)
}

///|
pub fn DrawArgument::new10(
  position : Point[Int],
  center : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new16(
    position,
    center,
    { x: 0, y: 0 },
    xscale,
    yscale,
    opacity,
    0.0,
  )
}

///|
pub fn DrawArgument::new12(
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new13({ x: 0, y: 0 }, xscale, yscale, opacity)
}

///|
pub fn DrawArgument::new13(
  position : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new10(position, position, xscale, yscale, opacity)
}

///|
pub fn DrawArgument::new14(
  position : Point[Int],
  flip : Bool,
  opacity~ : Double = 1.0
) -> DrawArgument {
  DrawArgument::new10(
    position,
    position,
    if flip {
      -1.0
    } else {
      1.0
    },
    1.0,
    opacity,
  )
}

///|
pub fn DrawArgument::new15(
  angle : Double,
  position : Point[Int],
  flip : Bool,
  opacity : Double
) -> DrawArgument {
  DrawArgument::new16(
    position,
    position,
    { x: 0, y: 0 },
    if flip {
      -1.0
    } else {
      1.0
    },
    1.0,
    opacity,
    angle,
  )
}

///|
pub fn DrawArgument::new16(
  position : Point[Int],
  center : Point[Int],
  stretch : Point[Int],
  xscale : Double,
  yscale : Double,
  opacity : Double,
  angle : Double
) -> DrawArgument {
  DrawArgument::new17(
    position,
    center,
    stretch,
    xscale,
    yscale,
    Color::new_rgba(1.0, 1.0, 1.0, opacity),
    angle,
  )
}

///|
pub fn DrawArgument::new17(
  position : Point[Int],
  center : Point[Int],
  stretch : Point[Int],
  xscale : Double,
  yscale : Double,
  color : Color,
  angle : Double
) -> DrawArgument {
  { pos: position, center, stretch, xscale, yscale, angle, color } // Assuming default value
}

///|
pub fn add_pos(self : DrawArgument, argpos : Point[Int]) -> DrawArgument {
  DrawArgument::new17(
    self.pos + argpos,
    self.center + argpos,
    self.stretch,
    self.xscale,
    self.yscale,
    self.color,
    self.angle,
  )
}

///|
pub fn add_opacity(self : DrawArgument, argopc : Double) -> DrawArgument {
  DrawArgument::new16(
    self.pos,
    self.center,
    self.stretch,
    self.xscale,
    self.yscale,
    self.color.a() * argopc,
    self.angle,
  )
}

///|
pub impl Add for DrawArgument with op_add(self : DrawArgument, o : DrawArgument) -> DrawArgument {
  DrawArgument::new17(
    self.pos + o.pos,
    self.center + o.center,
    self.stretch + o.stretch,
    self.xscale * o.xscale,
    self.yscale * o.yscale,
    self.color * o.color,
    self.angle + o.angle,
  )
}

///|
pub fn merge(self : DrawArgument, o : DrawArgument) -> DrawArgument {
  DrawArgument::new17(
    self.pos + o.pos,
    self.center + o.center,
    self.stretch + o.stretch,
    self.xscale * o.xscale,
    self.yscale * o.yscale,
    self.color * o.color,
    self.angle + o.angle,
  )
}

///|
pub impl Sub for DrawArgument with op_sub(self : DrawArgument, o : DrawArgument) -> DrawArgument {
  DrawArgument::new17(
    self.pos - o.pos,
    self.center - o.center,
    self.stretch - o.stretch,
    self.xscale / o.xscale,
    self.yscale / o.yscale,
    self.color / o.color,
    self.angle - o.angle,
  )
}

///|
pub fn get_rectangle(
  self : DrawArgument,
  origin : Point[Int],
  dimensions : Point[Int]
) -> Rectangle[Int] {
  let w = if self.stretch.x == 0 { dimensions.x } else { self.stretch.x }
  let h = if self.stretch.y == 0 { dimensions.y } else { self.stretch.y }
  let rlt = self.pos - self.center - origin
  let rl = rlt.x
  let rr = rlt.x + w
  let rt = rlt.y
  let rb = rlt.y + h
  let cx = self.center.x
  let cy = self.center.y
  Rectangle::from4(
    cx + (self.xscale * rl.to_double()).to_int(),
    cx + (self.xscale * rr.to_double()).to_int(),
    cy + (self.yscale * rt.to_double()).to_int(),
    cy + (self.yscale * rb.to_double()).to_int(),
  )
}

///|
pub fn get_pos(self : DrawArgument) -> Point[Int] {
  self.pos
}
