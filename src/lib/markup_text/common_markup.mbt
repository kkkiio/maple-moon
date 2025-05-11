///|
pub let color_map : Map[Char, ColorName] = {
  'b': ColorName::BLUE,
  'd': ColorName::VIOLET,
  'g': ColorName::GREEN,
  'k': ColorName::BLACK,
  'r': ColorName::RED,
}

///|
pub let font_weight_tag_map : Map[Char, Bool] = { 'n': false, 'e': true }

///|
typealias ColorName = @struct.ColorName
