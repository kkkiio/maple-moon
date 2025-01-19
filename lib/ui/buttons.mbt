///|
pub fn remove_cursor(buttons : Iter[ButtonModel]) -> Unit {
  for button in buttons {
    if button.get_state() == ButtonState::MOUSEOVER {
      button.set_state(ButtonState::NORMAL)
    }
  }
}

///|
pub fn send_cursor_to_btns(
  buttons : Iter[Button],
  container_pos : @struct.Point[Int],
  down : Bool,
  pos : @struct.Point[Int]
) -> CursorState {
  send_cursor_to_areas(
    buttons.filter_map(fn(b) { b.get_interactive_area() }),
    container_pos,
    down,
    pos,
  )
}

///|
pub fn send_cursor_to_areas(
  areas : Iter[InteractiveArea],
  container_pos : @struct.Point[Int],
  down : Bool,
  pos : @struct.Point[Int]
) -> CursorState {
  let mut ret = if down { CursorState::CLICKING } else { CursorState::IDLE }
  for area in areas {
    if area.bounds.shift(container_pos).contains(pos) {
      match area.state.val {
        ButtonState::NORMAL => {
          area.state.val = ButtonState::MOUSEOVER
          ret = CursorState::CAN_CLICK
        }
        ButtonState::MOUSEOVER =>
          if down {
            (area.on_click)()
            ret = CursorState::IDLE
          } else {
            ret = CursorState::CAN_CLICK
          }
        _ => ()
      }
    } else if area.state.val == ButtonState::MOUSEOVER {
      area.state.val = ButtonState::NORMAL
    }
  }
  ret
}
