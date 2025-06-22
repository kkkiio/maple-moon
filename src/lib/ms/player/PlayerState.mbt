///|
typealias @character.CharState

///|
trait PlayerState {
  initialize(Self, Player) -> Unit
  send_action(Self, Player, @keyboard.BasicActionId, Bool) -> Unit
  update(Self, Player) -> Unit
  update_state(Self, Player) -> Unit
}

///|
fn play_jumpsound() -> Unit {
  //   Sound::new(SoundName::SOUND_NAME_JUMP).play()
}

///|
struct PlayerNullState {} derive(Default)

///|
pub impl PlayerState for PlayerNullState with initialize(
  self : PlayerNullState,
  player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerNullState with send_action(
  self : PlayerNullState,
  player : Player,
  ka : @keyboard.BasicActionId,
  pressed : Bool
) -> Unit {

}

///|
pub impl PlayerState for PlayerNullState with update(
  self : PlayerNullState,
  player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerNullState with update_state(
  self : PlayerNullState,
  player : Player
) -> Unit {
  let state : CharState = if player.character.get_phobj().onground {
    if player.is_key_down(@keyboard.BasicActionId::LEFT) {
      player.set_direction(false)
      CharState::WALK
    } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
      player.set_direction(true)
      CharState::WALK
    } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
      CharState::PRONE
    } else {
      CharState::STAND
    }
  } else {
    let ladder = player.get_ladder()
    match ladder {
      Some(l) => if l.is_ladder() { CharState::LADDER } else { CharState::ROPE }
      None => CharState::FALL
    }
  }
  player.character.get_phobj().clear_flags()
  player.character.set_state(state)
}

///|
struct PlayerStandState {} derive(Default)

///|
pub impl PlayerState for PlayerStandState with initialize(
  self : PlayerStandState,
  player : Player
) -> Unit {
  player.character.get_phobj().t = @physics.PhysicsObjectType::NORMAL
}

///|
pub impl PlayerState for PlayerStandState with send_action(
  self : PlayerStandState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if player.is_attacking() {
    return
  }
  if down {
    match ka {
      @keyboard.BasicActionId::LEFT => {
        player.set_direction(false)
        player.set_state(CharState::WALK)
      }
      @keyboard.BasicActionId::RIGHT => {
        player.set_direction(true)
        player.set_state(CharState::WALK)
      }
      @keyboard.BasicActionId::JUMP => {
        play_jumpsound()
        player.character.get_phobj().vforce = -player.get_jumpforce()
      }
      @keyboard.BasicActionId::DOWN => player.set_state(CharState::PRONE)
      _ => ()
    }
  }
}

///|
pub impl PlayerState for PlayerStandState with update(
  self : PlayerStandState,
  player : Player
) -> Unit {
  if not(player.character.get_phobj().enablejd) {
    player.character
    .get_phobj()
    .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
pub impl PlayerState for PlayerStandState with update_state(
  self : PlayerStandState,
  player : Player
) -> Unit {
  if not(player.character.get_phobj().onground) {
    player.set_state(CharState::FALL)
  }
}

///|
struct PlayerWalkState {} derive(Default)

///|
pub impl PlayerState for PlayerWalkState with initialize(
  self : PlayerWalkState,
  player : Player
) -> Unit {
  player.character.get_phobj().t = @physics.PhysicsObjectType::NORMAL
}

///|
pub impl PlayerState for PlayerWalkState with send_action(
  self : PlayerWalkState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if player.is_attacking() {
    return
  }
  if down {
    match ka {
      @keyboard.BasicActionId::LEFT => player.set_direction(false)
      @keyboard.BasicActionId::RIGHT => player.set_direction(true)
      @keyboard.BasicActionId::JUMP => {
        play_jumpsound()
        player.character.get_phobj().vforce = -player.get_jumpforce()
      }
      @keyboard.BasicActionId::DOWN => player.set_state(CharState::PRONE)
      _ => ()
    }
  }
}

///|
pub fn haswalkinput(self : PlayerWalkState, player : Player) -> Bool {
  player.is_key_down(@keyboard.BasicActionId::LEFT) ||
  player.is_key_down(@keyboard.BasicActionId::RIGHT)
}

///|
pub impl PlayerState for PlayerWalkState with update(
  self : PlayerWalkState,
  player : Player
) -> Unit {
  if not(player.is_attacking()) && self.haswalkinput(player) {
    let hforce = if player.character.is_facing_right() {
      player.get_walkforce()
    } else {
      -player.get_walkforce()
    }
    player.character.get_phobj().hforce += hforce
  }
  if not(player.character.get_phobj().enablejd) {
    player.character
    .get_phobj()
    .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
pub impl PlayerState for PlayerWalkState with update_state(
  self : PlayerWalkState,
  player : Player
) -> Unit {
  if player.character.get_phobj().onground {
    if not(self.haswalkinput(player)) ||
      player.character.get_phobj().moving_object.hspeed == 0.0 {
      player.set_state(CharState::STAND)
    }
  } else {
    player.set_state(CharState::FALL)
  }
}

///|
struct PlayerFallState {} derive(Default)

///|
pub impl PlayerState for PlayerFallState with initialize(
  self : PlayerFallState,
  player : Player
) -> Unit {
  player.character.get_phobj().t = @physics.PhysicsObjectType::NORMAL
}

///|
pub impl PlayerState for PlayerFallState with send_action(
  self : PlayerFallState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.BasicActionId::LEFT => player.set_direction(false)
      @keyboard.BasicActionId::RIGHT => player.set_direction(true)
      _ => ()
    }
  }
}

///|
pub impl PlayerState for PlayerFallState with update(
  self : PlayerFallState,
  player : Player
) -> Unit {
  let hspeed = player.character.get_phobj().moving_object.hspeed
  if player.is_key_down(@keyboard.BasicActionId::LEFT) && hspeed > 0.0 {
    player.character.get_phobj().moving_object.hspeed -= 0.025
    if player.character.get_phobj().moving_object.hspeed < 0.0 {
      player.character.get_phobj().moving_object.hspeed = 0.0
    }
  } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) && hspeed < 0.0 {
    player.character.get_phobj().moving_object.hspeed += 0.025
    if player.character.get_phobj().moving_object.hspeed > 0.0 {
      player.character.get_phobj().moving_object.hspeed = 0.0
    }
  }
}

///|
pub impl PlayerState for PlayerFallState with update_state(
  self : PlayerFallState,
  player : Player
) -> Unit {
  if player.character.get_phobj().onground {
    if player.is_key_down(@keyboard.BasicActionId::LEFT) {
      player.set_direction(false)
      player.set_state(CharState::WALK)
    } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
      player.set_direction(true)
      player.set_state(CharState::WALK)
    } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
      player.set_state(CharState::PRONE)
    } else {
      player.set_state(CharState::STAND)
    }
  } else if player.is_underwater() {
    player.set_state(CharState::SWIM)
  }
}

// The prone state (Lying down)

///|
struct PlayerProneState {} derive(Default)

///|
pub impl PlayerState for PlayerProneState with initialize(
  self : PlayerProneState,
  player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerProneState with update_state(
  self : PlayerProneState,
  player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerProneState with send_action(
  self : PlayerProneState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.BasicActionId::JUMP =>
        if player.character.get_phobj().enablejd &&
          player.is_key_down(@keyboard.BasicActionId::DOWN) {
          play_jumpsound()
          player.character.get_phobj().moving_object.set_y(
            player.character.get_phobj().groundbelow,
          )
          player.set_state(CharState::FALL)
        }
      _ => ()
    }
  } else {
    match ka {
      @keyboard.BasicActionId::DOWN => player.set_state(CharState::STAND)
      _ => ()
    }
  }
}

///|
pub impl PlayerState for PlayerProneState with update(
  self : PlayerProneState,
  player : Player
) -> Unit {
  if not(player.character.get_phobj().enablejd) {
    player.character
    .get_phobj()
    .set_flag(@physics.PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
struct PlayerSitState {} derive(Default)

///|
pub impl PlayerState for PlayerSitState with initialize(
  self : PlayerSitState,
  _player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerSitState with update(
  self : PlayerSitState,
  _player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerSitState with update_state(
  self : PlayerSitState,
  _player : Player
) -> Unit {

}

///|
pub impl PlayerState for PlayerSitState with send_action(
  self : PlayerSitState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.BasicActionId::LEFT => {
        player.set_direction(false)
        player.set_state(CharState::WALK)
      }
      @keyboard.BasicActionId::RIGHT => {
        player.set_direction(true)
        player.set_state(CharState::WALK)
      }
      @keyboard.BasicActionId::JUMP => {
        play_jumpsound()
        player.set_state(CharState::STAND)
      }
      @keyboard.BasicActionId::UP => player.set_state(CharState::STAND)
      _ => ()
    }
  }
}

///|
struct PlayerFlyState {} derive(Default)

///|
pub impl PlayerState for PlayerFlyState with initialize(
  self : PlayerFlyState,
  player : Player
) -> Unit {
  player.character.get_phobj().t = if player.is_underwater() {
    @physics.PhysicsObjectType::SWIMMING
  } else {
    @physics.PhysicsObjectType::FLYING
  }
}

///|
pub impl PlayerState for PlayerFlyState with send_action(
  self : PlayerFlyState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.BasicActionId::LEFT => player.set_direction(false)
      @keyboard.BasicActionId::RIGHT => player.set_direction(true)
      _ => ()
    }
  }
}

///|
pub impl PlayerState for PlayerFlyState with update(
  self : PlayerFlyState,
  player : Player
) -> Unit {
  if player.is_attacking() {
    return
  }
  if player.is_key_down(@keyboard.BasicActionId::LEFT) {
    player.character.get_phobj().hforce = -player.get_flyforce()
  } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
    player.character.get_phobj().hforce = player.get_flyforce()
  }
  if player.is_key_down(@keyboard.BasicActionId::UP) {
    player.character.get_phobj().vforce = -player.get_flyforce()
  } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
    player.character.get_phobj().vforce = player.get_flyforce()
  }
}

///|
pub impl PlayerState for PlayerFlyState with update_state(
  self : PlayerFlyState,
  player : Player
) -> Unit {
  if player.character.get_phobj().onground && player.is_underwater() {
    let state = if player.is_key_down(@keyboard.BasicActionId::LEFT) {
      player.set_direction(false)
      CharState::WALK
    } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
      player.set_direction(true)
      CharState::WALK
    } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
      CharState::PRONE
    } else {
      CharState::STAND
    }
    player.set_state(state)
  }
}

///|
struct PlayerClimbState {} derive(Default)

///|
pub impl PlayerState for PlayerClimbState with initialize(
  self : PlayerClimbState,
  player : Player
) -> Unit {
  player.character.get_phobj().t = @physics.PhysicsObjectType::FIXATED
}

///|
pub impl PlayerState for PlayerClimbState with send_action(
  self : PlayerClimbState,
  player : Player,
  ka : @keyboard.BasicActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.BasicActionId::JUMP =>
        if player.is_key_down(@keyboard.BasicActionId::LEFT) {
          play_jumpsound()
          player.set_direction(false)
          player.character.get_phobj().moving_object.hspeed = -player.get_walkforce() *
            8.0
          player.character.get_phobj().moving_object.vspeed = -player.get_jumpforce() /
            1.5
          self.cancel_ladder(player)
        } else if player.is_key_down(@keyboard.BasicActionId::RIGHT) {
          play_jumpsound()
          player.set_direction(true)
          player.character.get_phobj().moving_object.hspeed = player.get_walkforce() *
            8.0
          player.character.get_phobj().moving_object.vspeed = -player.get_jumpforce() /
            1.5
          self.cancel_ladder(player)
        }
      _ => ()
    }
  }
}

///|
pub impl PlayerState for PlayerClimbState with update(
  self : PlayerClimbState,
  player : Player
) -> Unit {
  if player.is_key_down(@keyboard.BasicActionId::UP) {
    player.character.get_phobj().set_vspeed(-player.get_climbforce())
  } else if player.is_key_down(@keyboard.BasicActionId::DOWN) {
    player.character.get_phobj().set_vspeed(player.get_climbforce())
  } else {
    player.character.get_phobj().set_vspeed(0.0)
  }
}

///|
pub impl PlayerState for PlayerClimbState with update_state(
  self : PlayerClimbState,
  player : Player
) -> Unit {
  let y = player.character.get_phobj().get_y()
  let downwards = player.is_key_down(@keyboard.BasicActionId::DOWN)
  match player.get_ladder() {
    Some(ladder) =>
      if ladder.felloff(y, downwards) {
        self.cancel_ladder(player)
      }
    None => ()
  }
}

///|
pub fn PlayerClimbState::cancel_ladder(
  self : PlayerClimbState,
  player : Player
) -> Unit {
  player.set_state(CharState::FALL)
  player.set_ladder(None)
}
