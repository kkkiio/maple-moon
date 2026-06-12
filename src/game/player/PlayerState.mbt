///|
using @character {type CharState}

///|
fn haswalkinput(_player : Player) -> Bool {
  @keymap.is_pressed(@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_LEFT)) ||
  @keymap.is_pressed(@keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT))
}

///|
fn cancel_ladder(player : Player) -> Unit {
  player.set_state(CharState::FALL)
  player.set_ladder(None)
}
