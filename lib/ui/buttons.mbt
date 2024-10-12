typealias Point[T] = @struct.Point[T]

pub fn remove_cursor[K, V : Button](buttons : Iter2[K, V]) -> Unit {
  for _, button in buttons {
    if button.get_button_base().get_state() == ButtonState::MOUSEOVER {
      button.get_button_base().set_state(ButtonState::NORMAL)
    }
  }
}

pub fn send_cursor_to_buttons[K, V : Button](
  buttons : Iter2[K, V],
  self_position : @struct.Point[Int],
  on_btn_pressed : (K) -> ButtonState,
  down : Bool,
  pos : @struct.Point[Int]
) -> CursorState {
  let mut ret = if down { CursorState::CLICKING } else { CursorState::IDLE }
  for k, button in buttons {
    if button.get_button_base().is_active() &&
      button.bounds(self_position).contains(pos) {
      match button.get_button_base().get_state() {
        ButtonState::NORMAL => {
          // Sound::new(SoundName::BUTTON_OVER).play()
          button.get_button_base().set_state(ButtonState::MOUSEOVER)
          ret = CursorState::CAN_CLICK
        }
        ButtonState::MOUSEOVER =>
          if down {
            // Sound::new(SoundName::BUTTON_CLICK).play()
            button.get_button_base().set_state(on_btn_pressed(k))
            ret = CursorState::IDLE
          } else {
            ret = CursorState::CAN_CLICK
          }
        _ => ()
      }
    } else if button.get_button_base().get_state() == ButtonState::MOUSEOVER {
      button.get_button_base().set_state(ButtonState::NORMAL)
    }
  }
  ret
}
