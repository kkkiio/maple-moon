///|
struct UIStateLogin {
  elements : @sorted_map.T[UIElementType, @ui.Element]
  mut focused : UIElementType
  uis_to_remove : Array[UIElementType]
}

///|
fn UIStateLogin::new(login_module : @login.Module) -> UIStateLogin {
  let state = {
    elements: @sorted_map.new(),
    focused: UIElementType::UI_ELEMENT_NONE,
    uis_to_remove: [],
  }
  state.set_element(false, login_module.new_login_ui())
  state
}

///|
fn draw(
  self : UIStateLogin,
  inter : Double,
  cursor : @struct.Point[Int]
) -> Unit {
  self.elements.each(fn(_t, elem) {
    if elem.get_ui_model().is_active() {
      elem.draw(inter)
    }
  })
}

///|
fn update(self : UIStateLogin) -> Unit {
  self.uis_to_remove.each(fn(t) { self.elements.remove(t) })
  self.elements.each(fn(_t, elem) {
    if elem.get_ui_model().is_active() {
      elem.update()
    }
  })
}

///|
pub fn send_key(
  self : UIStateLogin,
  t : @keyboard.KeyType,
  action : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  match self.get(self.focused) {
    Some(focusedelement) =>
      if focusedelement.get_ui_model().is_active() {
        focusedelement.object.send_key(action, pressed, escape)
      } else {
        self.focused = UIElementType::UI_ELEMENT_NONE
      }
    None => ()
  }
}

///|
pub fn send_cursor(
  self : UIStateLogin,
  cursorstate : @ui.CursorState,
  cursorpos : @struct.Point[Int]
) -> @ui.CursorState {
  let clicked = cursorstate == @ui.CursorState::CLICKING ||
    cursorstate == @ui.CursorState::VSCROLL_IDLE
  match self.get(self.focused) {
    Some(focusedelement) =>
      if focusedelement.get_ui_model().is_active() {
        self.remove_cursor(self.focused)
        return focusedelement.send_cursor(clicked, cursorpos)
      } else {
        self.focused = UIElementType::UI_ELEMENT_NONE
        return cursorstate
      }
    None => ()
  }
  match self.get_front() {
    Some(front) => {
      self.remove_cursor(front.0)
      front.1.send_cursor(clicked, cursorpos)
    }
    None => @ui.CursorState::IDLE
  }
}

///|
pub fn remove(self : UIStateLogin, key : UIElementType) -> Unit {
  if self.focused == key {
    self.focused = UIElementType::UI_ELEMENT_NONE
  }
  match self.elements.get(key) {
    Some(element) => {
      element.get_ui_model().deactivate()
      self.uis_to_remove.push(key)
    }
    None => ()
  }
}

///|
pub fn get(self : UIStateLogin, t : UIElementType) -> @ui.Element? {
  self.elements.get(t)
}

///|
pub fn get_front(self : UIStateLogin) -> (@ui.UIElementType, @ui.Element)? {
  // TODO: use rev_iter
  self.elements
  .iter()
  .fold(
    fn(acc, it) { if it.1.get_ui_model().is_active() { Some(it) } else { acc } },
    init=None,
  )
}

///|
pub fn get_front_by_types(
  self : UIStateLogin,
  types : Array[UIElementType]
) -> @ui.Element? {
  let mut front : @ui.Element? = None
  types.rev_each(fn(t) {
    if not(front.is_empty()) {
      return
    }
    match self.elements.get(t) {
      Some(elem) => if elem.get_ui_model().is_active() { front = Some(elem) }
      None => ()
    }
  })
  front
}

///|
pub fn get_front_by_pos(
  self : UIStateLogin,
  pos : @struct.Point[Int]
) -> @ui.Element? {
  // TODO: use rev_iter
  self.elements
  .iter()
  .fold(
    fn(acc, it) {
      let element = it.1
      if element.get_ui_model().is_active() &&
        element.get_ui_model().is_in_range(pos) {
        Some(element)
      } else {
        acc
      }
    },
    init=None,
  )
}

///|
pub fn remove_cursor(self : UIStateLogin, keep : UIElementType) -> Unit {
  for key, element in self.elements {
    if element.get_ui_model().is_active() && key != keep {
      element.object.remove_cursor()
    }
  }
}

///|
pub fn set_element(
  self : UIStateLogin,
  focused : Bool,
  elem : @ui.Element
) -> Unit {
  let t = elem.key
  self.remove(t)
  if focused {
    self.focused = t
  }
  self.elements[t] = elem
}

///|
pub fn doubleclick(self : UIStateLogin, pos : @struct.Point[Int]) -> Unit {

}
