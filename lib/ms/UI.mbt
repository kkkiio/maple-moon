// app/src/main/cpp/src/IO/UI.h
// app/src/main/cpp/src/IO/UI.cpp

enum UiState {
  LOGIN
  GAME
  CASHSHOP
}

struct UI {
  mut state : UIState
  //         std::unordered_map<int16_t, TouchInfo> touch_phase_;
  //         Keyboard keyboard_;
  cursor : Cursor
  //         ScrollingNotice scrolling_notice_;
  //         UIMobileInput mobile_input_;

  //         std::optional<std::reference_wrapper<Textfield>> focused_text_field_;
  //         std::unordered_map<int32_t, bool> is_key_down_;

  mut enabled : Bool
  //         bool quitted_;
  //         bool caps_lock_enabled_;

  //         std::function<void()> fn_toggle_full_screen_;
  //         std::function<void()> fn_set_clipboard_;
  //         std::function<std::string()> fn_get_clipboard_;
}

let ui : UI = UI::new()

fn UI::new() -> UI {
  let ui = {
    state: UIStateNull::default(),
    cursor: Cursor::new(),
    enabled: true,
  }
  ui.change_state(UiState::GAME) // for test
  ui
}

fn UI::get() -> UI {
  ui
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
  self.state = match id {
    // UiState::LOGIN => UIStateLogin::new()
    UiState::GAME => UIStateGame::new(20)
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
