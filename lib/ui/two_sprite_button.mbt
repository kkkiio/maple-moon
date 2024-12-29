///|
struct TwoSpriteButton {
  base : ButtonModel
  textures : @utils.BoolPair[@graphics.Texture]
  npos : Point[Int]
  spos : Point[Int]
}

///|
pub fn TwoSpriteButton::new(
  disabled : @graphics.Texture,
  enabled : @graphics.Texture,
  np~ : Point[Int] = @struct.Point::default(),
  sp~ : Point[Int] = np,
  active~ : Bool = true,
  state~ : ButtonState = ButtonState::NORMAL
) -> TwoSpriteButton {
  let textures = @utils.BoolPair::new(disabled, enabled)
  {
    base: ButtonModel::default()..set_active(active)..set_state(state),
    textures,
    npos: np,
    spos: sp,
  }
}

///|
pub fn draw(self : TwoSpriteButton, parentpos : Point[Int]) -> Unit {
  if self.base.is_active() {
    let selected = self.base.get_state() == ButtonState::MOUSEOVER ||
      self.base.get_state() == ButtonState::PRESSED
    self.textures
    .op_get(selected)
    .draw(@graphics.DrawArgument::new(position=self.npos + parentpos))
  }
}

///|
pub impl UIButton for TwoSpriteButton with bounds(self : TwoSpriteButton) -> @struct.Rectangle[
  Int,
] {
  let selected = self.base.get_state() == ButtonState::MOUSEOVER ||
    self.base.get_state() == ButtonState::PRESSED
  let pos = (if selected { self.spos } else { self.npos }) -
    self.textures.op_get(selected).get_origin()
  return @struct.Rectangle::new(
    pos,
    pos + self.textures.op_get(selected).get_dimensions(),
  )
}

///|
pub fn width(self : TwoSpriteButton) -> Int {
  let selected = self.base.get_state() == ButtonState::MOUSEOVER ||
    self.base.get_state() == ButtonState::PRESSED
  return self.textures.op_get(selected).width()
}

///|
pub fn origin(self : TwoSpriteButton) -> Point[Int] {
  let selected = self.base.get_state() == ButtonState::MOUSEOVER ||
    self.base.get_state() == ButtonState::PRESSED
  return self.textures.op_get(selected).get_origin()
}

///|
pub fn get_button_base(self : TwoSpriteButton) -> ButtonModel {
  self.base
}

///|
pub fn update(self : TwoSpriteButton) -> Unit {

}
