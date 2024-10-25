typealias Point[T] = @struct.Point[T]

pub fn remove_cursor(buttons : Iter[ButtonModel]) -> Unit {
  for button in buttons {
    if button.get_state() == ButtonState::MOUSEOVER {
      button.set_state(ButtonState::NORMAL)
    }
  }
}

pub fn send_cursor_to_buttons[K, V : UIButton](
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

pub fn send_cursor_to_btns(
  buttons : Iter[Button],
  self_position : @struct.Point[Int],
  down : Bool,
  pos : @struct.Point[Int]
) -> CursorState {
  let mut ret = if down { CursorState::CLICKING } else { CursorState::IDLE }
  for button in buttons {
    let model = button.object.get_button_base()
    if model.is_active() && button.object.bounds(self_position).contains(pos) {
      match model.get_state() {
        ButtonState::NORMAL => {
          // Sound::new(SoundName::BUTTON_OVER).play()
          model.set_state(ButtonState::MOUSEOVER)
          ret = CursorState::CAN_CLICK
        }
        ButtonState::MOUSEOVER =>
          if down {
            // Sound::new(SoundName::BUTTON_CLICK).play()
            model.set_state(
              match button.on_click {
                Some(f) => f()
                None => ButtonState::IDENTITY
              },
            )
            ret = CursorState::IDLE
          } else {
            ret = CursorState::CAN_CLICK
          }
        _ => ()
      }
    } else if model.get_state() == ButtonState::MOUSEOVER {
      model.set_state(ButtonState::NORMAL)
    }
  }
  ret
}
