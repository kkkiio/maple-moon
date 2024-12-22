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
    base: { active, pressed: false, position: @struct.Point::default(), state },
    textures,
    npos: np,
    spos: sp,
  }
}

///|
pub fn draw(self : TwoSpriteButton, parentpos : Point[Int]) -> Unit {
  if self.base.active {
    let selected = self.base.state == ButtonState::MOUSEOVER ||
      self.base.state == ButtonState::PRESSED
    if selected {
      self.textures
      .op_get(true)
      .draw(self.spos + parentpos |> @graphics.DrawArgument::new)
    } else {
      self.textures
      .op_get(false)
      .draw(self.npos + parentpos |> @graphics.DrawArgument::new)
    }
  }
}

///|
pub fn bounds(
  self : TwoSpriteButton,
  parentpos : Point[Int]
) -> @struct.Rectangle[Int] {
  let selected = self.base.state == ButtonState::MOUSEOVER ||
    self.base.state == ButtonState::PRESSED
  let (absp, dim) = if selected {
    (
      self.spos + parentpos - self.textures.op_get(true).get_origin(),
      self.textures.op_get(true).get_dimensions(),
    )
  } else {
    (
      self.npos + parentpos - self.textures.op_get(false).get_origin(),
      self.textures.op_get(false).get_dimensions(),
    )
  }
  return @struct.Rectangle::new(absp, absp + dim)
}

///|
pub fn width(self : TwoSpriteButton) -> Int {
  let selected = self.base.state == ButtonState::MOUSEOVER ||
    self.base.state == ButtonState::PRESSED
  return self.textures.op_get(selected).width()
}

///|
pub fn origin(self : TwoSpriteButton) -> Point[Int] {
  let selected = self.base.state == ButtonState::MOUSEOVER ||
    self.base.state == ButtonState::PRESSED
  return self.textures.op_get(selected).get_origin()
}

///|
pub fn get_button_base(self : TwoSpriteButton) -> ButtonModel {
  self.base
}

///|
pub fn update(self : TwoSpriteButton) -> Unit {

}

///|
pub fn send_cursor(
  self : TwoSpriteButton,
  _a : Bool,
  _b : Point[Int]
) -> CursorState {
  return CursorState::IDLE
}
