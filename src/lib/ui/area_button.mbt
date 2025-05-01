///| An invisible button which is only defined by it's area.
struct AreaButton {
  model : ButtonModel
  dimension : @struct.Point[Int]
}

///|
pub fn AreaButton::new(
  pos : @struct.Point[Int],
  dim : @struct.Point[Int]
) -> AreaButton {
  let model = ButtonModel::default()..set_position(pos)
  { model, dimension: dim }
}

///|
pub fn AreaButton::get_button_base(self : AreaButton) -> ButtonModel {
  self.model
}

///|
pub fn AreaButton::draw(self : AreaButton, _p : @struct.Point[Int]) -> Unit {

}

///|
pub fn AreaButton::update(self : AreaButton) -> Unit {

}

///|
pub fn send_cursor(
  self : AreaButton,
  _b : Bool,
  _p : @struct.Point[Int]
) -> CursorState {
  CursorState::IDLE
}

///|
pub fn bounds(self : AreaButton) -> @struct.Rectangle[Int] {
  let pos = self.model.position
  @struct.Rectangle::new(pos, pos + self.dimension)
}

///|
pub fn width(self : AreaButton) -> Int {
  self.dimension.x
}

///|
pub fn origin(self : AreaButton) -> @struct.Point[Int] {
  @struct.Point::new(0, 0)
}
