///|
pub(all) struct UI {
  mut state : &UIState?
  get_keyboard_mapping : (String) -> @keyboard.Mapping?
  cursor : Cursor
  is_key_down : Map[String, Bool]
}

///|
pub fn UI::new(get_keyboard_mapping : (String) -> @keyboard.Mapping?) -> UI {
  {
    state: None,
    get_keyboard_mapping,
    cursor: Cursor::new(),
    is_key_down: Map::new(),
  }
}

///|
pub fn UI::draw(self : UI, alpha : Double) -> Unit {
  match self.state {
    Some(state) => state.draw(alpha, self.cursor.get_position())
    None => ()
  }
  self.cursor.draw(alpha)
}

///|
pub fn UI::update(self : UI) -> Unit {
  match self.state {
    Some(state) => state.update()
    None => ()
  }
  self.cursor.update()
}

///|
pub fn send_cursor_pos(self : UI, pos : Point[Int]) -> Unit {
  self.send_cursor(pos, self.cursor.get_state())
}

///|
pub fn send_cursor_pressed(self : UI, pressed : Bool) -> Unit {
  let cursorstate = if pressed {
    CursorState::CLICKING
  } else {
    CursorState::IDLE
  }
  let cursorpos = self.cursor.get_position()
  self.send_cursor(cursorpos, cursorstate)
}

///|
pub fn UI::send_cursor(
  self : UI,
  cursorpos : Point[Int],
  cursorstate : CursorState
) -> Unit {
  let nextstate = match self.state {
    Some(state) => state.send_cursor(cursorstate, cursorpos)
    None => CursorState::IDLE
  }
  self.cursor.set_state(nextstate)
  self.cursor.set_position(cursorpos)
}

///|
pub fn change_state(self : UI, state : &UIState) -> Unit {
  self.state = Some(state)
}

///|
pub fn send_key(self : UI, keycode : String, pressed : Bool) -> Unit {
  guard self.state is Some(state) else { return }
  let mapping = (self.get_keyboard_mapping)(keycode)
  let escape = keycode == @keyboard.escape
  state.send_key(mapping, pressed, escape)
  self.is_key_down[keycode] = pressed
}

///|
fn get_element(self : UI, element_type : UIElementType) -> Element? {
  match self.state {
    Some(state) => state.get(element_type)
    None => None
  }
}

///|
pub fn set_element(self : UI, focused : Bool, elem : Element) -> Unit {
  guard self.state is Some(state) else { return }
  state.set_element(focused, elem)
}

///|
pub impl Container for UI with add_ui(self : UI, elem : Element, focused : Bool) -> Unit {
  guard self.state is Some(state) else { return }
  state.set_element(focused, elem)
}

///|
pub impl Container for UI with remove_ui(
  self : UI,
  element_type : UIElementType
) -> Unit {
  guard self.state is Some(state) else { return }
  state.remove(element_type)
}

///|
pub fn doubleclick(self : UI) -> Unit {
  guard self.state is Some(state) else { return }
  let pos = self.cursor.get_position()
  state.doubleclick(pos)
}

///|
pub(open) trait UIState {
  draw(Self, Double, Point[Int]) -> Unit
  update(Self) -> Unit
  send_key(Self, @keyboard.Mapping?, Bool, Bool) -> Unit
  send_cursor(Self, CursorState, Point[Int]) -> CursorState
  doubleclick(Self, Point[Int]) -> Unit
  set_element(Self, Bool, Element) -> Unit
  remove(Self, UIElementType) -> Unit
  get(Self, UIElementType) -> Element?
  get_front_by_types(Self, Array[UIElementType]) -> Element?
}
