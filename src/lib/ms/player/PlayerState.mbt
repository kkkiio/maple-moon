///|
using @character {type CharState}

///|
fn play_jumpsound() -> Unit {
  //   Sound::new(SoundName::SOUND_NAME_JUMP).play()
}

///|
fn haswalkinput(player : Player) -> Bool {
  player.is_key_down(@keyboard.BasicActionId::LEFT) ||
  player.is_key_down(@keyboard.BasicActionId::RIGHT)
}

///|
fn cancel_ladder(player : Player) -> Unit {
  player.set_state(CharState::FALL)
  player.set_ladder(None)
}
