pub enum ButtonState {
  NORMAL
  DISABLED
  MOUSEOVER
  PRESSED
  IDENTITY
} derive(Eq, Compare, Debug)

pub let all_button_states : @immut/sorted_map.Map[ButtonState, Int] = @immut/sorted_map.from_array(
  [(NORMAL, 0), (DISABLED, 1), (MOUSEOVER, 2), (PRESSED, 3), (IDENTITY, 4)],
)

pub fn int_value(self : ButtonState) -> Int {
  all_button_states[self].unwrap()
}

fn hash(self : ButtonState) -> Int {
  self.int_value()
}

pub trait Button {
  draw(Self, Point[Int]) -> Unit
  update(Self) -> Unit
  bounds(Self, Point[Int]) -> Rectangle[Int]
  width(Self) -> Int
  origin(Self) -> Point[Int]
  send_cursor(Self, Bool, Point[Int]) -> CursorState
  get_state(Self) -> ButtonState
  set_state(Self, ButtonState) -> Unit
  is_active(Self) -> Bool
  set_active(Self, Bool) -> Unit
  in_combobox(Self, Point[Int]) -> Bool
  // get_selected(Self) -> Int
  // set_position(Self, Point[Int]) -> Unit
  // toggle_pressed(Self) -> Unit
  // is_pressed(Self) -> Bool
  // hash(Self) -> Int
}

struct ButtonBase {
  mut state : ButtonState
  mut position : Point[Int]
  mut active : Bool
  mut pressed : Bool
}

pub fn in_combobox(self : ButtonBase, point : Point[Int]) -> Bool {
  false
}

pub fn get_selected(self : ButtonBase) -> Int {
  0
}

pub fn set_position(self : ButtonBase, pos : Point[Int]) -> Unit {
  self.position = pos
}

pub fn set_state(self : ButtonBase, s : ButtonState) -> Unit {
  if s == ButtonState::IDENTITY {
    return
  }
  self.state = s
}

pub fn set_active(self : ButtonBase, a : Bool) -> Unit {
  self.active = a
}

pub fn toggle_pressed(self : ButtonBase) -> Unit {
  self.pressed = self.pressed.not()
}

pub fn is_active(self : ButtonBase) -> Bool {
  self.active && self.state != ButtonState::DISABLED
}

pub fn get_state(self : ButtonBase) -> ButtonState {
  self.state
}

pub fn is_pressed(self : ButtonBase) -> Bool {
  self.pressed
}
