/// An invisible button which is only defined by it's area.
struct AreaButton {
  model : ButtonModel
  dimension : @struct.Point[Int]
}

pub fn AreaButton::new(
  pos : @struct.Point[Int],
  dim : @struct.Point[Int]
) -> AreaButton {
  let model : ButtonModel = {
    position: pos,
    state: ButtonState::NORMAL,
    active: true,
    pressed: false,
  }
  { model, dimension: dim }
}

pub fn get_button_base(self : AreaButton) -> ButtonModel {
  self.model
}

pub fn draw(self : AreaButton, _p : @struct.Point[Int]) -> Unit {

}

pub fn update(self : AreaButton) -> Unit {

}

pub fn send_cursor(
  self : AreaButton,
  _b : Bool,
  _p : @struct.Point[Int]
) -> CursorState {
  CursorState::IDLE
}

pub fn bounds(
  self : AreaButton,
  parentpos : @struct.Point[Int]
) -> @struct.Rectangle[Int] {
  let absp = self.model.position + parentpos
  @struct.Rectangle::new(absp, absp + self.dimension)
}

pub fn width(self : AreaButton) -> Int {
  self.dimension.x
}

pub fn origin(self : AreaButton) -> @struct.Point[Int] {
  @struct.Point::new(0, 0)
}
