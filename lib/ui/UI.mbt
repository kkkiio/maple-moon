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
  guard let Some(state) = self.state else { None => return }
  let mapping = (self.get_keyboard_mapping)(keycode)
  let mut sent = false
  let types = Array::new()
  let escape = keycode == @keyboard.escape
  let tab = keycode == @keyboard.tab
  let enter = keycode == @keyboard.enter || keycode == @keyboard.numpadEnter
  let up_down = keycode == @keyboard.arrowUp || keycode == @keyboard.arrowDown
  let left_right = keycode == @keyboard.arrowLeft ||
    keycode == @keyboard.arrowRight
  let arrows = up_down || left_right
  fn get_active_ui_by_type(t) {
    self.get_element(t).filter(fn(it) { it.get_ui_model().is_active() })
  }

  let active_ui = [
      get_active_ui_by_type(UIElementType::NPC_TALK),
      // get_active_ui_by_type(UIElementType::STATUS_BAR), // TODO: check menu active
      get_active_ui_by_type(UIElementType::CHANNEL),
      get_active_ui_by_type(UIElementType::WORLD_MAP),
      get_active_ui_by_type(UIElementType::OPTION_MENU),
      get_active_ui_by_type(UIElementType::SHOP),
      get_active_ui_by_type(UIElementType::JOYPAD),
      get_active_ui_by_type(UIElementType::CHAT_RANK),
      get_active_ui_by_type(UIElementType::QUIT),
    ]
    .iter()
    .flat_map(fn(it) { it |> @option.iter })
    .find_first(fn(it) { it.get_ui_model().is_active() })
  match active_ui {
    Some(it) => {
      it.object.send_key(
        mapping.map_or(0, fn(it) { it.action }),
        pressed,
        escape,
      )
      |> ignore
      sent = true
    }
    None => {
      if escape || tab || enter || arrows {
        types.push(UIElementType::WORLD_SELECT)
        types.push(UIElementType::UI_ELEMENT_CHAR_SELECT)
        types.push(UIElementType::UI_ELEMENT_RACE_SELECT)
        types.push(UIElementType::CLASS_CREATION)
        types.push(UIElementType::LOGIN_NOTICE)
        types.push(UIElementType::LOGIN_NOTICE_CONFIRM)
        types.push(UIElementType::LOGIN_WAIT)
      }
      if escape {
        types.push(UIElementType::SOFT_KEYBOARD)
        types.push(UIElementType::NOTICE)
        types.push(UIElementType::KEY_CONFIG)
        types.push(UIElementType::CHAT)
        types.push(UIElementType::EVENT)
        types.push(UIElementType::STATS_INFO)
        types.push(UIElementType::ITEM_INVENTORY)
        types.push(UIElementType::EQUIP_INVENTORY)
        types.push(UIElementType::SKILL_BOOK)
        types.push(UIElementType::QUEST_LOG)
        types.push(UIElementType::USER_LIST)
        types.push(UIElementType::NPC_TALK)
        types.push(UIElementType::CHAR_INFO)
      } else if enter {
        types.push(UIElementType::SOFT_KEYBOARD)
        types.push(UIElementType::NOTICE)
      } else if tab {
        types.push(UIElementType::ITEM_INVENTORY)
        types.push(UIElementType::EQUIP_INVENTORY)
        types.push(UIElementType::SKILL_BOOK)
        types.push(UIElementType::QUEST_LOG)
        types.push(UIElementType::USER_LIST)
      }
      if types.length() > 0 {
        match state.get_front_by_types(types) {
          Some(element) => {
            element.object.send_key(
              mapping.map_or(0, fn(it) { it.action }),
              pressed,
              escape,
            )
            sent = true
          }
          None => ()
        }
      }
    }
  }
  if not(sent) {
    state.send_key(mapping, pressed, escape)
  }
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
pub fn add_ui(self : UI, elem : Element, focused : Bool) -> Unit {
  guard self.state is Some(state) else { return }
  state.set_element(focused, elem)
}

///|
pub fn remove_ui(self : UI, element_type : UIElementType) -> Unit {
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
