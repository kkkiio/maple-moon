// app/src/main/cpp/src/IO/UI.h
// app/src/main/cpp/src/IO/UI.cpp

enum UiState {
  LOGIN
  GAME
  CASHSHOP
}

struct Textfield {}

struct UI {
  mut state : UIState
  keyboard : Keyboard
  cursor : Cursor
  //         ScrollingNotice scrolling_notice_;
  //         UIMobileInput mobile_input_;

  //         std::optional<std::reference_wrapper<Textfield>> focused_text_field_;
  focused_text_field : Textfield?
  is_key_down : Map[String, Bool]
  mut enabled : Bool
  mut quitted : Bool
  mut caps_lock_enabled : Bool

  //         std::function<void()> fn_toggle_full_screen_;
  //         std::function<void()> fn_set_clipboard_;
  //         std::function<std::string()> fn_get_clipboard_;
}

let g_ui : UI = UI::new()

fn UI::new() -> UI {
  let ui = {
    state: UIStateNull::default(),
    cursor: Cursor::new(),
    keyboard: Keyboard::default(),
    focused_text_field: None,
    is_key_down: Map::new(),
    enabled: true,
    quitted: false,
    caps_lock_enabled: false,
  }
  ui.change_state(UiState::GAME) // for test
  ui
}

fn UI::get() -> UI {
  g_ui
}

pub fn draw(self : UI, alpha : Double) -> Unit {
  //         state_->draw(alpha, cursor_.get_position());
  //         scrolling_notice_.draw(alpha);
  self.cursor.draw(alpha)
  //         mobile_input_.draw();
}

fn update(self : UI) -> Unit {
  //         state_->update();
  //         scrolling_notice_.update();
  //         cursor_.update();
  self.cursor.update()
  //         mobile_input_.update();
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
  let nextstate = self.state.send_cursor(cursorstate, cursorpos)
  self.cursor.set_state(nextstate)
  self.cursor.set_position(cursorpos)
}

fn change_state(self : UI, id : UiState) -> Unit {
  match id {
    UiState::LOGIN => self.state = UIStateLogin::new()
    UiState::GAME => self.state = UIStateGame::new(20)
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

fn opt_as_iter[T](opt : T?) -> Iter[T] {
  match opt {
    Some(v) => Iter::singleton(v)
    None => Iter::empty()
  }
}

pub fn send_key(self : UI, keycode : String, pressed : Bool) -> Unit {
  if (self.is_key_down.get_or_default(@kb.altLeft, false) || self.is_key_down.get_or_default(
    @kb.altRight, false,
  )) && (self.is_key_down.get_or_default(@kb.enter, false) || self.is_key_down.get_or_default(
    @kb.numpadEnter, false,
  )) {
    // Window::get().toggle_fullscreen()

    self.is_key_down[@kb.altLeft] = false
    self.is_key_down[@kb.altRight] = false
    self.is_key_down[@kb.enter] = false
    self.is_key_down[@kb.numpadEnter] = false
    return
  }
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
      let npctalk = self.get_element(UIElementType::NPC_TALK)
      let statusbar = self.get_element(UIElementType::STATUS_BAR)
      let channel = self.get_element(UIElementType::CHANNEL)
      let worldmap = self.get_element(UIElementType::WORLD_MAP)
      let optionmenu = self.get_element(UIElementType::OPTION_MENU)
      let shop = self.get_element(UIElementType::SHOP)
      let joypad = self.get_element(UIElementType::JOYPAD)
      let rank = self.get_element(UIElementType::CHAT_RANK)
      let quit = self.get_element(UIElementType::QUIT)
      match
        [
          npctalk, statusbar, channel, worldmap, optionmenu, shop, joypad, rank,
          quit,
        ].iter().flat_map(fn(it) { it |> opt_as_iter }).find_first(
          fn { _ => true },
        ) {
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
            match self.state.get_front_by_types(types) {
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
        // let chatbar = self.get_element(UIElementType::CHAT_BAR)
        if escape {
          // if chatbar && chatbar.get().is_chat_open() {
          //   chatbar.get().send_key(mapping.action, pressed, escape)
          // } else {
          self.state.send_key(mapping.t, mapping.action, pressed, escape)
          // }
        } else if enter {
          // if chatbar {
          // chatbar.get().send_key(mapping.action, pressed, escape)
          // } else {
          self.state.send_key(mapping.t, mapping.action, pressed, escape)
          // }
        } else {
          self.state.send_key(mapping.t, mapping.action, pressed, escape)
        }
      }
    }
  }
  self.is_key_down[keycode] = pressed
}

fn get_element(self : UI, element_type : UIElementType) -> UIElement? {
  self.state.get(element_type)
}

fn emplace[T : UIElement + UIElementDescriptor](self : UI, f : () -> T) -> Unit {
  self.state.set_element(
    T::const_type(),
    T::const_toggled(),
    T::const_focused(),
    fn() { f() },
  )
}

pub fn quit(self : UI) -> Unit {
  self.quitted = true
}
