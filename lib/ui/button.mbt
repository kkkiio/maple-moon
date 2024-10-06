pub enum ButtonState {
  NORMAL
  DISABLED
  MOUSEOVER
  PRESSED
  IDENTITY
} derive(Eq, Hash)

pub trait Button {
  draw(Self, Point[Int]) -> Unit
  update(Self) -> Unit
  bounds(Self, Point[Int]) -> @struct.Rectangle[Int]
  width(Self) -> Int
  origin(Self) -> Point[Int]
  send_cursor(Self, Bool, Point[Int]) -> CursorState
  get_button_base(Self) -> ButtonModel
  // get_selected(Self) -> Int
  // set_position(Self, Point[Int]) -> Unit
  // toggle_pressed(Self) -> Unit
  // is_pressed(Self) -> Bool
}

pub struct ButtonModel {
  mut state : ButtonState
  mut position : Point[Int]
  mut active : Bool
  mut pressed : Bool
}

pub fn ButtonModel::default() -> ButtonModel {
  {
    state: ButtonState::NORMAL,
    position: Point::default(),
    active: true,
    pressed: false,
  }
}

pub fn get_selected(self : ButtonModel) -> Int {
  0
}

pub fn set_position(self : ButtonModel, pos : Point[Int]) -> Unit {
  self.position = pos
}

pub fn set_state(self : ButtonModel, s : ButtonState) -> Unit {
  if s == ButtonState::IDENTITY {
    return
  }
  self.state = s
}

pub fn set_active(self : ButtonModel, a : Bool) -> Unit {
  self.active = a
}

pub fn toggle_pressed(self : ButtonModel) -> Unit {
  self.pressed = self.pressed.not()
}

pub fn is_active(self : ButtonModel) -> Bool {
  self.active && self.state != ButtonState::DISABLED
}

pub fn get_state(self : ButtonModel) -> ButtonState {
  self.state
}

pub fn is_pressed(self : ButtonModel) -> Bool {
  self.pressed
}
