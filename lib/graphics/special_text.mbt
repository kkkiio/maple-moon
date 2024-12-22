///|
struct OutlinedText {
  inner : Text
  l : Text
  r : Text
  t : Text
  b : Text
}

///|
pub fn OutlinedText::new(
  font : FontId,
  alignment : TextAlignment,
  inner_color : @struct.ColorName,
  outer_color : @struct.ColorName
) -> OutlinedText {
  {
    inner: Text::new(font, alignment, inner_color),
    l: Text::new(font, alignment, outer_color),
    r: Text::new(font, alignment, outer_color),
    t: Text::new(font, alignment, outer_color),
    b: Text::new(font, alignment, outer_color),
  }
}

///|
pub fn draw(self : OutlinedText, parent_pos : Point[Int]) -> Unit {
  self.l.draw({ ..parent_pos, x: parent_pos.x - 1 })
  self.r.draw({ ..parent_pos, x: parent_pos.x + 1 })
  self.t.draw({ ..parent_pos, y: parent_pos.y - 1 })
  self.b.draw({ ..parent_pos, y: parent_pos.y + 1 })
  self.inner.draw(parent_pos)
}

///|
pub fn change_text(self : OutlinedText, text : String) -> Unit {
  self.inner.change_text(text)
  self.l.change_text(text)
  self.r.change_text(text)
  self.t.change_text(text)
  self.b.change_text(text)
}

///|
pub fn change_color(self : OutlinedText, color : @struct.ColorName) -> Unit {
  self.inner.change_color(color)
}

///|
pub fn width(self : OutlinedText) -> Int {
  self.inner.width()
}

///|
pub(all) struct ShadowText {
  mut top : Text
  mut shadow : Text
}

///|
pub fn ShadowText::new(
  font : FontId,
  alignment : TextAlignment,
  top_color : @struct.ColorName,
  shadow_color : @struct.ColorName
) -> ShadowText {
  {
    top: Text::new(font, alignment, top_color),
    shadow: Text::new(font, alignment, shadow_color),
  }
}

///|
pub fn draw(self : ShadowText, parent_pos : Point[Int]) -> Unit {
  self.shadow.draw({ x: parent_pos.x + 1, y: parent_pos.y + 1 })
  self.top.draw(parent_pos)
}

///|
pub fn change_text(self : ShadowText, text : String) -> Unit {
  self.top.change_text(text)
  self.shadow.change_text(text)
}

///|
pub fn change_color(self : ShadowText, color : @struct.ColorName) -> Unit {
  self.top.change_color(color)
}

///|
pub fn width(self : ShadowText) -> Int {
  self.top.width()
}
