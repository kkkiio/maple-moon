///|
pub(all) enum Code {
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

///|
pub fn Code::int_value(self : Code) -> Int {
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

///|
pub fn Code::color(self : Code) -> Color {
  self.int_value() |> Color::from_value
}

///|
pub(all) enum ColorName {
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

///|
pub fn ColorName::css_name(self : ColorName) -> String {
  match self {
    BLACK => "black"
    WHITE => "white"
    YELLOW => "yellow"
    BLUE => "blue"
    RED => "red"
    DARKRED => "darkred"
    BROWN => "brown"
    JAMBALAYA => "jambalaya"
    LIGHTGREY => "lightgrey"
    DARKGREY => "darkgrey"
    ORANGE => "orange"
    MEDIUMBLUE => "mediumblue"
    VIOLET => "violet"
    TOBACCOBROWN => "tobaccobrown"
    EAGLE => "eagle"
    LEMONGRASS => "lemongrass"
    TUNA => "tuna"
    GALLERY => "gallery"
    DUSTYGRAY => "dustygray"
    EMPEROR => "emperor"
    MINESHAFT => "mineshaft"
    HALFANDHALF => "halfandhalf"
    ENDEAVOUR => "endeavour"
    BROWNDERBY => "brownderby"
    PORCELAIN => "porcelain"
    IRISHCOFFEE => "irishcoffee"
    BOULDER => "boulder"
    GREEN => "green"
    LIGHTGREEN => "lightgreen"
    JAPANESELAUREL => "japaneselaurel"
    GRAYOLIVE => "grayolive"
    ELECTRICLIME => "electriclime"
    SUPERNOVA => "supernova"
    CHARTREUSE => "chartreuse"
    MALIBU => "malibu"
  }
}

///|
pub impl ToJson for ColorName with to_json(self) {
  self.css_name().to_json()
}

///|
pub impl Show for ColorName with output(self, logger) {
  logger.write_string(self.css_name())
}

///|
pub fn ColorName::color(self : ColorName) -> Color {
  match self {
    BLACK => clr_black
    WHITE => clr_white
    YELLOW => clr_yellow
    BLUE => clr_blue
    RED => clr_red
    DARKRED => clr_dark_red
    BROWN => clr_brown
    JAMBALAYA => clr_jambalaya
    LIGHTGREY => clr_light_grey
    DARKGREY => clr_dark_grey
    ORANGE => clr_orange
    MEDIUMBLUE => clr_medium_blue
    VIOLET => clr_violet
    TOBACCOBROWN => clr_tobacco_brown
    EAGLE => clr_eagle
    LEMONGRASS => clr_lemon_grass
    TUNA => clr_tuna
    GALLERY => clr_gallery
    DUSTYGRAY => clr_dusty_gray
    EMPEROR => clr_emperor
    MINESHAFT => clr_mine_shaft
    HALFANDHALF => clr_half_and_half
    ENDEAVOUR => clr_endeavour
    BROWNDERBY => clr_brown_derby
    PORCELAIN => clr_porcelain
    IRISHCOFFEE => clr_irish_coffee
    BOULDER => clr_boulder
    GREEN => clr_green
    LIGHTGREEN => clr_light_green
    JAPANESELAUREL => clr_japanese_laurel
    GRAYOLIVE => clr_gray_olive
    ELECTRICLIME => clr_electric_lime
    SUPERNOVA => clr_supernova
    CHARTREUSE => clr_chartreuse
    MALIBU => clr_malibu
  }
}

///|
pub let color_names : FixedArray[ColorName] = [
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

///|
let clr_black : Color = Color::new_rgba(0.00, 0.00, 0.00, 1.0)

///|
let clr_white : Color = Color::new_rgba(1.00, 1.00, 1.00, 1.0)

///|
let clr_yellow : Color = Color::new_rgba(1.00, 1.00, 0.00, 1.0)

///|
let clr_blue : Color = Color::new_rgba(0.00, 0.00, 1.00, 1.0)

///|
let clr_red : Color = Color::new_rgba(1.00, 0.00, 0.00, 1.0)

///|
let clr_dark_red : Color = Color::new_rgba(0.80, 0.30, 0.30, 1.0)

///|
let clr_brown : Color = Color::new_rgba(0.50, 0.25, 0.00, 1.0)

///|
let clr_jambalaya : Color = Color::new_rgba(0.34, 0.20, 0.07, 1.0)

///|
let clr_light_grey : Color = Color::new_rgba(0.50, 0.50, 0.50, 1.0)

///|
let clr_dark_grey : Color = Color::new_rgba(0.25, 0.25, 0.25, 1.0)

///|
let clr_orange : Color = Color::new_rgba(1.00, 0.50, 0.00, 1.0)

///|
let clr_medium_blue : Color = Color::new_rgba(0.00, 0.75, 1.00, 1.0)

///|
let clr_violet : Color = Color::new_rgba(0.50, 0.00, 0.50, 1.0)

///|
let clr_tobacco_brown : Color = Color::new_rgba(0.47, 0.40, 0.27, 1.0)

///|
let clr_eagle : Color = Color::new_rgba(0.74, 0.74, 0.67, 1.0)

///|
let clr_lemon_grass : Color = Color::new_rgba(0.60, 0.60, 0.54, 1.0)

///|
let clr_tuna : Color = Color::new_rgba(0.20, 0.20, 0.27, 1.0)

///|
let clr_gallery : Color = Color::new_rgba(0.94, 0.94, 0.94, 1.0)

///|
let clr_dusty_gray : Color = Color::new_rgba(0.60, 0.60, 0.60, 1.0)

///|
let clr_emperor : Color = Color::new_rgba(0.34, 0.34, 0.34, 1.0)

///|
let clr_mine_shaft : Color = Color::new_rgba(0.20, 0.20, 0.20, 1.0)

///|
let clr_half_and_half : Color = Color::new_rgba(1.00, 1.00, 0.87, 1.0)

///|
let clr_endeavour : Color = Color::new_rgba(0.00, 0.40, 0.67, 1.0)

///|
let clr_brown_derby : Color = Color::new_rgba(0.30, 0.20, 0.10, 1.0)

///|
let clr_porcelain : Color = Color::new_rgba(0.94, 0.95, 0.95, 1.0)

///|
let clr_irish_coffee : Color = Color::new_rgba(0.34, 0.27, 0.14, 1.0)

///|
let clr_boulder : Color = Color::new_rgba(0.47, 0.47, 0.47, 1.0)

///|
let clr_green : Color = Color::new_rgba(0.00, 0.75, 0.00, 1.0)

///|
let clr_light_green : Color = Color::new_rgba(0.00, 1.00, 0.00, 1.0)

///|
let clr_japanese_laurel : Color = Color::new_rgba(0.00, 0.50, 0.00, 1.0)

///|
let clr_gray_olive : Color = Color::new_rgba(0.67, 0.67, 0.60, 1.0)

///|
let clr_electric_lime : Color = Color::new_rgba(0.80, 1.00, 0.00, 1.0)

///|
let clr_supernova : Color = Color::new_rgba(1.00, 0.80, 0.00, 1.0)

///|
let clr_chartreuse : Color = Color::new_rgba(0.47, 1.00, 0.00, 1.0)

///|
let clr_malibu : Color = Color::new_rgba(0.47, 0.80, 1.00, 1.0)

///|
pub let clr_opaque : Color = clr_white

///|
pub fn ColorName::int_value(self : ColorName) -> Int {
  color_names.search(self).unwrap()
}

///|
pub(all) struct Color(Double, Double, Double, Double) derive(Show, Eq, ToJson)

///|
pub fn Color::new_rgba(
  red : Double,
  green : Double,
  blue : Double,
  alpha : Double,
) -> Color {
  Color(red, green, blue, alpha)
}

///|
pub fn new_array(comps : FixedArray[Double]) -> Color {
  Color(comps[0], comps[1], comps[2], comps[3])
}

///|
pub fn Color::from_value(code : Int) -> Color {
  Color(
    (code >> 24).land(0xFF).to_double() / 255.0,
    (code >> 16).land(0xFF).to_double() / 255.0,
    (code >> 8).land(0xFF).to_double() / 255.0,
    code.land(0xFF).to_double() / 255.0,
  )
}

///|
pub fn Color::from_code(name : Code) -> Color {
  name.color()
}

///|
pub fn Color::from_name(name : ColorName) -> Color {
  name.color()
}

///|
pub fn Color::invisible(self : Color) -> Bool {
  self.3 <= 0.0
}

///|
pub fn Color::r(self : Color) -> Double {
  self.0
}

///|
pub fn Color::g(self : Color) -> Double {
  self.1
}

///|
pub fn Color::b(self : Color) -> Double {
  self.2
}

///|
pub fn Color::a(self : Color) -> Double {
  self.3
}

///|
pub fn Color::blend(self : Color, other : Color, alpha : Double) -> Color {
  Color(
    @utils.lerp(self.0, other.0, alpha),
    @utils.lerp(self.1, other.1, alpha),
    @utils.lerp(self.2, other.2, alpha),
    @utils.lerp(self.3, other.3, alpha),
  )
}

///|
pub impl Mul for Color with mul(self, o) {
  Color(self.r() * o.r(), self.g() * o.g(), self.b() * o.b(), self.a() * o.a())
}

///|
pub impl Div for Color with div(self, o) {
  Color(self.r() / o.r(), self.g() / o.g(), self.b() / o.b(), self.a() / o.a())
}

///|
struct IntColor(Int) derive(Show, Eq, Hash)

///|
pub fn IntColor::from_color(color : Color) -> IntColor {
  ((color.r() * 255).to_int() << 24) |
  ((color.g() * 255).to_int() << 16) |
  ((color.b() * 255).to_int() << 8) |
  (color.a() * 255).to_int()
}

///|
pub fn IntColor::r(self : IntColor) -> Int {
  (self.0 >> 24) & 0xFF
}

///|
pub fn IntColor::g(self : IntColor) -> Int {
  (self.0 >> 16) & 0xFF
}

///|
pub fn IntColor::b(self : IntColor) -> Int {
  (self.0 >> 8) & 0xFF
}

///|
pub fn IntColor::a(self : IntColor) -> Int {
  self.0 & 0xFF
}
