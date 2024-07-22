pub enum Code {
  CNONE
  CWHITE
  CBLACK
  CRED
  CGREEN
  CBLUE
  CYELLOW
  CTURQUOISE
  CPURPLE
} derive(Eq)

pub fn int_value(self : Code) -> Int {
  match self {
    CNONE => 0x00000000
    CWHITE => 0xFFFFFFFF
    CBLACK => 0x000000FF
    CRED => 0xFF0000FF
    CGREEN => 0x00FF00FF
    CBLUE => 0x0000FFFF
    CYELLOW => 0xFFFF00FF
    CTURQUOISE => 0x00FFFFFF
    CPURPLE => 0xFF00FFFF
  }
}

pub enum Name {
  BLACK
  WHITE
  YELLOW
  BLUE
  RED
  DARKRED
  BROWN
  JAMBALAYA
  LIGHTGREY
  DARKGREY
  ORANGE
  MEDIUMBLUE
  VIOLET
  TOBACCOBROWN
  EAGLE
  LEMONGRASS
  TUNA
  GALLERY
  DUSTYGRAY
  EMPEROR
  MINESHAFT
  HALFANDHALF
  ENDEAVOUR
  BROWNDERBY
  PORCELAIN
  IRISHCOFFEE
  BOULDER
  GREEN
  LIGHTGREEN
  JAPANESELAUREL
  GRAYOLIVE
  ELECTRICLIME
  SUPERNOVA
  CHARTREUSE
  MALIBU
} derive(Eq)

pub let color_names : FixedArray[Name] = [
  BLACK,
  WHITE,
  YELLOW,
  BLUE,
  RED,
  DARKRED,
  BROWN,
  JAMBALAYA,
  LIGHTGREY,
  DARKGREY,
  ORANGE,
  MEDIUMBLUE,
  VIOLET,
  TOBACCOBROWN,
  EAGLE,
  LEMONGRASS,
  TUNA,
  GALLERY,
  DUSTYGRAY,
  EMPEROR,
  MINESHAFT,
  HALFANDHALF,
  ENDEAVOUR,
  BROWNDERBY,
  PORCELAIN,
  IRISHCOFFEE,
  BOULDER,
  GREEN,
  LIGHTGREEN,
  JAPANESELAUREL,
  GRAYOLIVE,
  ELECTRICLIME,
  SUPERNOVA,
  CHARTREUSE,
  MALIBU,
]

pub let colors : FixedArray[FixedArray[Double]] = [
  [0.00, 0.00, 0.00], // Black
  [1.00, 1.00, 1.00], // White
  [1.00, 1.00, 0.00], // Yellow
  [0.00, 0.00, 1.00], // Blue
  [1.00, 0.00, 0.00], // Red
  [0.80, 0.30, 0.30], // DarkRed
  [0.50, 0.25, 0.00], // Brown
  [0.34, 0.20, 0.07], // Jambalaya
  [0.50, 0.50, 0.50], // Lightgrey
  [0.25, 0.25, 0.25], // Darkgrey
  [1.00, 0.50, 0.00], // Orange
  [0.00, 0.75, 1.00], // Mediumblue
  [0.50, 0.00, 0.50], // Violet
  [0.47, 0.40, 0.27], // Tobacco Brown
  [0.74, 0.74, 0.67], // Eagle
  [0.60, 0.60, 0.54], // Lemon Grass
  [0.20, 0.20, 0.27], // Tuna
  [0.94, 0.94, 0.94], // Gallery
  [0.60, 0.60, 0.60], // Dusty Gray
  [0.34, 0.34, 0.34], // Emperor
  [0.20, 0.20, 0.20], // Mine Shaft
  [1.00, 1.00, 0.87], // Half and Half
  [0.00, 0.40, 0.67], // Endeavour
  [0.30, 0.20, 0.10], // Brown Derby
  [0.94, 0.95, 0.95], // Porcelain
  [0.34, 0.27, 0.14], // Irish Coffee
  [0.47, 0.47, 0.47], // Boulder
  [0.00, 0.75, 0.00], // Green (Mob HP Bar)
  [0.00, 1.00, 0.00], // Light Green (Mob HP Bar)
  [0.00, 0.50, 0.00], // Japanese Laurel (Mob HP Bar)
  [0.67, 0.67, 0.60], // Gray Olive
  [0.80, 1.00, 0.00], // Electric Lime
  [1.00, 0.80, 0.00], // Supernova
  [0.47, 1.00, 0.00], // Chartreuse
  [0.47, 0.80, 1.00], // Malibu
]

pub fn int_value(self : Name) -> Int {
  color_names.search(self).unwrap()
}

pub type Color (Double, Double, Double, Double) derive(Debug, Show)

pub fn Color::new_rgba(
  red : Double,
  green : Double,
  blue : Double,
  alpha : Double
) -> Color {
  (red, green, blue, alpha)
}

pub fn new_array(comps : FixedArray[Double]) -> Color {
  (comps[0], comps[1], comps[2], comps[3])
}

pub fn Color::from_value(code : Int) -> Color {
  (
    // code >> 24 & 0xFF as Double / 255.0,
    code.lsr(24).land(0xFF).to_double() / 255.0,
    // (code >> 16 & 0xFF) as Double / 255.0,
    code.lsr(16).land(0xFF).to_double() / 255.0,
    // (code >> 8 & 0xFF) as Double / 255.0,
    code.lsr(8).land(0xFF).to_double() / 255.0,
    // (code & 0xFF) as Double / 255.0
    code.land(0xFF).to_double() / 255.0,
  )
}

pub fn Color::from_code(name : Code) -> Color {
  from_value(name.int_value())
}

pub fn invisible(self : Color) -> Bool {
  self.0.3 <= 0.0
}

pub fn r(self : Color) -> Double {
  self.0.0
}

pub fn g(self : Color) -> Double {
  self.0.1
}

pub fn b(self : Color) -> Double {
  self.0.2
}

pub fn a(self : Color) -> Double {
  self.0.3
}

pub fn blend(self : Color, other : Color, alpha : Double) -> Color {
  (
    lerp(self.0.0, other.0.0, alpha),
    lerp(self.0.1, other.0.1, alpha),
    lerp(self.0.2, other.0.2, alpha),
    lerp(self.0.3, other.0.3, alpha),
  )
}

pub fn op_mul(self : Color, o : Color) -> Color {
  (self.r() * o.r(), self.g() * o.g(), self.b() * o.b(), self.a() * o.a())
}

pub fn op_div(self : Color, o : Color) -> Color {
  (self.r() / o.r(), self.g() / o.g(), self.b() / o.b(), self.a() / o.a())
}

//https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0811r3.html
fn lerp(a : Double, b : Double, t : Double) -> Double {
  // Exact, monotonic, bounded, determinate, and (for a=b=0) consistent:
  if (a <= 0.0 && b >= 0.0) || (a >= 0.0 && b <= 0.0) {
    return t * b + (1.0 - t) * a
  }
  // exact
  if t == 1.0 {
    return b
  }

  // Exact at t=0, monotonic except near t=1,
  // bounded, determinate, and consistent:
  let x = a + t * (b - a)
  // monotonic near t=1
  return if t > 1.0 == (b > a) {
    @math.maximum(b, x)
  } else {
    @math.minimum(b, x)
  }
}
