typealias Point[T] = @struct.Point[T]

pub struct UIButtons {
  buttons : Map[Int, Button]
}

pub fn UIButtons::default() -> UIButtons {
  { buttons: {} }
}

pub fn UIButtons::new() -> UIButtons {
  { buttons: {} }
}

pub fn draw(self : UIButtons, position : Point[Int]) -> Unit {
  self.buttons.each(fn(_k, button) { button.draw(position) })
}

pub fn update(self : UIButtons) -> Unit {
  self.buttons.each(fn(_k, button) { button.update() })
}

pub fn remove_cursor(self : UIButtons) -> Unit {
  self.buttons.each(
    fn(_k, button) {
      if button.get_button_base().get_state() == ButtonState::MOUSEOVER {
        button.get_button_base().set_state(ButtonState::NORMAL)
      }
    },
  )
}

pub fn send_cursor(
  self : UIButtons,
  self_position : Point[Int],
  get_state_under_pressed : (Int) -> ButtonState,
  down : Bool,
  pos : Point[Int]
) -> CursorState {
  let mut ret = if down { CursorState::CLICKING } else { CursorState::IDLE }
  self.buttons.each(
    fn(k, button) {
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
              button.get_button_base().set_state(get_state_under_pressed(k))
              ret = CursorState::IDLE
            } else {
              ret = CursorState::CAN_CLICK
            }
          _ => ()
        }
      } else if button.get_button_base().get_state() == ButtonState::MOUSEOVER {
        button.get_button_base().set_state(ButtonState::NORMAL)
      }
    },
  )
  ret
}
