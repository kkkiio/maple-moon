enum UiState {
  LOGIN
  GAME
  // CASHSHOP
}

struct Textfield {}

struct UI {
  mut state : UIState?
  keyboard : Keyboard
  cursor : @ui.Cursor
  //         std::optional<std::reference_wrapper<Textfield>> focused_text_field_;
  focused_text_field : Textfield?
  is_key_down : Map[String, Bool]
  mut enabled : Bool
  mut caps_lock_enabled : Bool
}

let g_ui : UI = UI::new()

fn UI::new() -> UI {
  let ui = {
    state: None,
    cursor: @ui.Cursor::new(),
    keyboard: Keyboard::default(),
    focused_text_field: None,
    is_key_down: Map::new(),
    enabled: true,
    caps_lock_enabled: false,
  }
  ui.change_state(UiState::LOGIN) // for test
  ui
}

fn UI::get() -> UI {
  g_ui
}

pub fn draw(self : UI, alpha : Double) -> Unit {
  match self.state {
    Some(state) => state.draw(alpha, self.cursor.get_position())
    None => ()
  }
  self.cursor.draw(alpha)
}

fn update(self : UI) -> Unit {
  match self.state {
    Some(state) => state.update()
    None => ()
  }
  self.cursor.update()
}

pub fn send_cursor_pos(self : UI, pos : Point[Int]) -> Unit {
  self.send_cursor(pos, self.cursor.get_state())
}

pub fn send_cursor_pressed(self : UI, pressed : Bool) -> Unit {
  let cursorstate = if pressed && self.enabled {
    CursorState::CLICKING
  } else {
    CursorState::IDLE
  }
  let cursorpos = self.cursor.get_position()
  self.send_cursor(cursorpos, cursorstate)

  // if (focused_text_field_ && pressed) {
  //     Cursor::State tstate =
  //             focused_text_field_->get().send_cursor(cursorpos, pressed);

  //     switch (tstate) {
  //         case Cursor::State::IDLE:
  //             focused_text_field_ = {};
  //             break;
  //     }
  // }
}

pub fn send_cursor(
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

fn change_state(self : UI, id : UiState) -> Unit {
  match id {
    UiState::LOGIN => self.state = Some(UIStateLogin::new())
    UiState::GAME => self.state = Some(UIStateGame::new())
    // UiState::CASHSHOP => UIStateCashShop::default(),
  }
}

fn enable(self : UI) -> Unit {
  self.enabled = true
}

fn disable(self : UI) -> Unit {
  self.enabled = false
}

fn is_enabled(self : UI) -> Bool {
  self.enabled
}

pub fn send_key(self : UI, keycode : String, pressed : Bool) -> Unit {
  guard let Some(state) = self.state else { None => return  }
  if self.is_key_down.get_or_default(self.keyboard.capslock_code(), false) {
    self.caps_lock_enabled = self.caps_lock_enabled.not()
  }
  match self.focused_text_field {
    Some(_focused_text_field) =>
      // let ctrl = self.is_key_down.get_or_default(
      //     self.keyboard.left_ctrl_code(),
      //     false,
      //   ) || self.is_key_down.get_or_default(
      //     self.keyboard.right_ctrl_code(),
      //     false,
      //   )
      // if ctrl {
      //   if pressed.not() {
      //     let action = self.keyboard.get_ctrl_action(keycode)

      //     match action {
      //         @KeyAction.Id::COPY => Window::get().set_clipboard(focused_text_field.get_text())
      //         @KeyAction.Id::PASTE => self.focused_text_field.get().add_string(Window::get().get_clipboard())
      //         _ => ()
      //     }
      //   }
      // } else {
      //   let shift = self.is_key_down.get_or_default(
      //       self.keyboard.left_shift_code(),
      //       false,
      //     ) || self.is_key_down.get_or_default(
      //       self.keyboard.right_shift_code(),
      //       false,
      //     ) || self.caps_lock_enabled
      //   let mapping = self.keyboard.get_text_mapping(keycode, shift)
      //   if mapping.type_ != @KeyType.Id::TEXT {
      //     focused_text_field.send_key(mapping.type_, mapping.action, pressed)
      //   }
      // }
      ()
    None => {
      let mapping = self.keyboard.get_mapping(keycode)
      let mut sent = false
      let types = Array::new()
      let escape = keycode == @kb.escape
      let tab = keycode == @kb.tab
      let enter = keycode == @kb.enter || keycode == @kb.numpadEnter
      let up_down = keycode == @kb.arrowUp || keycode == @kb.arrowDown
      let left_right = keycode == @kb.arrowLeft || keycode == @kb.arrowRight
      let arrows = up_down || left_right
      fn get_active_ui_by_type(t : UIElementType) -> UIElement? {
        self
        .get_element(t)
        .filter(fn(it) { it.get_ui_element_base().is_active() })
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
        .find_first(fn(it) { it.get_ui_element_base().is_active() })
      match active_ui {
        Some(it) => {
          it.send_key(mapping.action, pressed, escape) |> ignore
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
                element.send_key(mapping.action, pressed, escape)
                sent = true
              }
              None => ()
            }
          }
        }
      }
      if sent.not() {
        state.send_key(mapping.t, mapping.action, pressed, escape)
      }
    }
  }
  self.is_key_down[keycode] = pressed
}

fn get_element(self : UI, element_type : UIElementType) -> UIElement? {
  match self.state {
    Some(state) => state.get(element_type)
    None => None
  }
}

/// @alert deprecated "Use set_element/toggle_element instead"
fn emplace[T : @ui.UIElement + @ui.UIElementDescriptor](
  self : UI,
  f : () -> T
) -> Unit {
  guard let Some(state) = self.state else { None => return  }
  if T::const_toggled() {
    state.toggle_element(T::const_type(), T::const_focused(), fn() { f() })
  } else {
    state.set_element(T::const_focused(), f())
  }
}

pub fn set_element[T : @ui.UIElement](
  self : UI,
  focused : Bool,
  elem : T
) -> Unit {
  guard let Some(state) = self.state else { None => return  }
  state.set_element(focused, elem)
}

pub fn toggle_element[T : @ui.UIElement + @ui.UIElementDescriptor](
  self : UI,
  f : () -> T
) -> Unit {
  guard let Some(state) = self.state else { None => return  }
  state.toggle_element(T::const_type(), T::const_focused(), fn() { f() })
}
