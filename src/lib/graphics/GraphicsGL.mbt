///|
using @struct {type Range}

///|
struct TextKey {
  text : String
  font_id : FontId
  text_alignment : TextAlignment
  color : @struct.IntColor
  max_width : Int?
} derive(Eq, Hash)

///|
pub(all) enum TextAlignment {
  LEFT
  CENTER
  RIGHT
} derive(Eq, Hash)

///|
priv struct Leftover {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

///|
fn Leftover::fromxywh(x : Int, y : Int, width : Int, height : Int) -> Leftover {
  let left = x
  let right = x + width
  let top = y
  let bottom = y + height
  { left, right, top, bottom }
}

///|
fn Leftover::width(self : Leftover) -> Int {
  self.right - self.left
}

///|
fn Leftover::height(self : Leftover) -> Int {
  self.bottom - self.top
}

///|
impl @quadtree.QuadCompare for Leftover with compare_to(
  self : Leftover,
  other : Leftover,
) -> @quadtree.Direction {
  let wg = self.width() >= other.width()
  let hg = self.height() >= other.height()
  match (wg, hg) {
    (true, true) => @quadtree.Direction::TR
    (true, false) => @quadtree.Direction::BR
    (false, true) => @quadtree.Direction::TL
    (false, false) => @quadtree.Direction::BL
  }
}

///|
priv struct TexOffset {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

///|
fn TexOffset::new(x : Int, y : Int, width : Int, height : Int) -> TexOffset {
  { left: x, right: x + width, top: y, bottom: y + height }
}

///|
pub(all) enum FontId {
  A11M
  A11B
  A12M
  A12B
  A13M
  A13B
  A15B
  A18M
} derive(Eq, Show, Hash)

///|
pub fn FontId::is_bold(self : FontId) -> Bool {
  match self {
    A11B | A12B | A13B | A15B => true
    _ => false
  }
}

///|
pub fn FontId::height(self : FontId) -> Int {
  match self {
    A11M | A11B => 11
    A12M | A12B => 12
    A13M | A13B => 13
    A15B => 15
    A18M => 18
  }
}
