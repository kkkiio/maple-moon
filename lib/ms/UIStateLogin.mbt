struct UIStateLogin {
  elements : @sorted_map.T[UIElementType, UIElement]
  mut focused : UIElementType
  uis_to_remove : Array[UIElementType]
}

fn UIStateLogin::new() -> UIStateLogin {
  let state = {
    elements: @sorted_map.new(),
    focused: UIElementType::UI_ELEMENT_NONE,
    uis_to_remove: [],
  }
  // let start_shown = Configuration::get().get_start_shown()
  // if start_shown {
  //   state.emplace(UILogo::new())
  // } else {
  state.set_element(UILogin::const_focused(), UILogin::new())
  // }
  state
}

fn draw(self : UIStateLogin, inter : Double, cursor : Point[Int]) -> Unit {
  self.elements.each(
    fn(_t, elem) {
      if elem.get_ui_element_base().is_active() {
        elem.draw(inter)
      }
    },
  )

  // if (tooltip_) {
  //     tooltip_->get().draw(cursor + Point<int16_t>(0, 22));
  // }

}

fn update(self : UIStateLogin) -> Unit {
  self.uis_to_remove.each(fn(t) { self.elements.remove(t) })
  self.elements.each(
    fn(_t, elem) { if elem.get_ui_element_base().is_active() { elem.update() } },
  )
}

pub fn send_key(
  self : UIStateLogin,
  t : @KeyType.Id,
  action : Int,
  pressed : Bool,
  escape : Bool
) -> Unit {
  match self.get(self.focused) {
    Some(focusedelement) =>
      if focusedelement.get_ui_element_base().is_active() {
        focusedelement.send_key(action, pressed, escape)
      } else {
        self.focused = UIElementType::UI_ELEMENT_NONE
      }
    None => ()
  }
}

pub fn send_cursor(
  self : UIStateLogin,
  cursorstate : CursorState,
  cursorpos : Point[Int]
) -> CursorState {
  let clicked = cursorstate == CursorState::CLICKING ||
    cursorstate == CursorState::VSCROLL_IDLE
  match self.get(self.focused) {
    Some(focusedelement) =>
      if focusedelement.get_ui_element_base().is_active() {
        self.remove_cursor(focusedelement.get_type())
        return focusedelement.send_cursor(clicked, cursorpos)
      } else {
        self.focused = UIElementType::UI_ELEMENT_NONE
        return cursorstate
      }
    None => ()
  }
  match self.get_front() {
    Some(front) => {
      self.remove_cursor(front.get_type())
      front.send_cursor(clicked, cursorpos)
    }
    None => CursorState::IDLE
  }
}

pub fn remove(self : UIStateLogin, type_ : UIElementType) -> Unit {
  if self.focused == type_ {
    self.focused = UIElementType::UI_ELEMENT_NONE
  }
  match self.elements.get(type_) {
    Some(element) => {
      element.get_ui_element_base().deactivate()
      self.uis_to_remove.push(type_)
    }
    None => ()
  }
}

pub fn get(self : UIStateLogin, type_ : UIElementType) -> UIElement? {
  // self.elements.get(type_)
  None
}

pub fn get_front(self : UIStateLogin) -> UIElement? {
  // TODO: use rev_iter
  self.elements
  .iter()
  .fold(
    fn(acc, it) {
      if it.1.get_ui_element_base().is_active() {
        Some(it.1)
      } else {
        acc
      }
    },
    init=None,
  )
}

pub fn get_front_by_types(
  self : UIStateLogin,
  types : Array[UIElementType]
) -> UIElement? {
  let mut front : UIElement? = None
  types.rev_each(
    fn(t) {
      if front.is_empty().not() {
        return
      }
      match self.elements.get(t) {
        Some(elem) =>
          if elem.get_ui_element_base().is_active() {
            front = Some(elem)
          }
        None => ()
      }
      // let elem = 
      // if elem.map(UIElement::is_active).or(false) {
      //   front = elem
      // }
    },
  )
  front
}

pub fn get_front_by_pos(self : UIStateLogin, pos : Point[Int]) -> UIElement? {
  // let mut front : UIElement? = None
  // all_types.rev_each(
  //   fn(t) {
  //     if front.is_empty().not() {
  //       return
  //     }
  //     let element = self.elements[t]
  //     if element.filter(UIElement::is_active).map(fn(e) { e.is_in_range(pos) }).or(
  //       false,
  //     ) {
  //       front = element
  //     }
  //   },
  // )
  // TODO: use rev_iter
  self.elements
  .iter()
  .fold(
    fn(acc, it) {
      if it.1.get_ui_element_base().is_active() && it.1.is_in_range(pos) {
        Some(it.1)
      } else {
        acc
      }
    },
    init=None,
  )
}

pub fn remove_cursor(self : UIStateLogin, type_ : UIElementType) -> Unit {
  self.elements.each(
    fn(_type, element) {
      if element.get_ui_element_base().is_active() &&
        element.get_type() != type_ {
        element.remove_cursor()
      }
    },
  )
}

pub fn set_element(
  self : UIStateLogin,
  focused : Bool,
  elem : UIElement
) -> Unit {
  let t = elem.get_type()
  self.remove(t)
  if focused {
    self.focused = t
  }
  self.elements[t] = elem
}

pub fn toggle_element(
  self : UIStateLogin,
  t : UIElementType,
  focused : Bool,
  f : () -> UIElement
) -> Unit {
  self.set_element(focused, f())
}

pub fn doubleclick(self : UIStateLogin, pos : Point[Int]) -> Unit {

}
