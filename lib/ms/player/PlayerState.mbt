///|
typealias PhysicsObjectType = @physics.PhysicsObjectType

///|
typealias PhysicsObjectFlag = @physics.PhysicsObjectFlag

///|
typealias CharState = @character.CharState

///|
trait PlayerState {
  initialize(Self, Player) -> Unit
  send_action(Self, Player, @keyboard.ActionId, Bool) -> Unit
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
pub fn initialize(self : PlayerNullState, player : Player) -> Unit {

}

///|
pub fn send_action(
  self : PlayerNullState,
  player : Player,
  ka : @keyboard.ActionId,
  pressed : Bool
) -> Unit {

}

///|
pub fn update(self : PlayerNullState, player : Player) -> Unit {

}

///|
pub fn update_state(self : PlayerNullState, player : Player) -> Unit {
  let state : CharState = if player.get_phobj().onground {
    if player.is_key_down(@keyboard.ActionId::LEFT) {
      player.set_direction(false)
      CharState::WALK
    } else if player.is_key_down(@keyboard.ActionId::RIGHT) {
      player.set_direction(true)
      CharState::WALK
    } else if player.is_key_down(@keyboard.ActionId::DOWN) {
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
  player.get_phobj().clear_flags()
  player.set_state(state)
}

///|
struct PlayerStandState {} derive(Default)

///|
pub fn initialize(self : PlayerStandState, player : Player) -> Unit {
  player.get_phobj().t = PhysicsObjectType::NORMAL
}

///|
pub fn send_action(
  self : PlayerStandState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if player.is_attacking() {
    return
  }
  if down {
    match ka {
      @keyboard.ActionId::LEFT => {
        player.set_direction(false)
        player.set_state(CharState::WALK)
      }
      @keyboard.ActionId::RIGHT => {
        player.set_direction(true)
        player.set_state(CharState::WALK)
      }
      @keyboard.ActionId::JUMP => {
        play_jumpsound()
        player.get_phobj().vforce = -player.get_jumpforce()
      }
      @keyboard.ActionId::DOWN => player.set_state(CharState::PRONE)
      _ => ()
    }
  }
}

///|
pub fn update(self : PlayerStandState, player : Player) -> Unit {
  if not(player.get_phobj().enablejd) {
    player.get_phobj().set_flag(PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
pub fn update_state(self : PlayerStandState, player : Player) -> Unit {
  if not(player.get_phobj().onground) {
    player.set_state(CharState::FALL)
  }
}

///|
struct PlayerWalkState {} derive(Default)

///|
pub fn initialize(self : PlayerWalkState, player : Player) -> Unit {
  player.get_phobj().t = PhysicsObjectType::NORMAL
}

///|
pub fn send_action(
  self : PlayerWalkState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if player.is_attacking() {
    return
  }
  if down {
    match ka {
      @keyboard.ActionId::LEFT => player.set_direction(false)
      @keyboard.ActionId::RIGHT => player.set_direction(true)
      @keyboard.ActionId::JUMP => {
        play_jumpsound()
        player.get_phobj().vforce = -player.get_jumpforce()
      }
      @keyboard.ActionId::DOWN => player.set_state(CharState::PRONE)
      _ => ()
    }
  }
}

///|
pub fn haswalkinput(self : PlayerWalkState, player : Player) -> Bool {
  player.is_key_down(@keyboard.ActionId::LEFT) ||
  player.is_key_down(@keyboard.ActionId::RIGHT)
}

///|
pub fn update(self : PlayerWalkState, player : Player) -> Unit {
  if player.is_attacking().not() && self.haswalkinput(player) {
    let hforce = if player.is_facing_right() {
      player.get_walkforce()
    } else {
      -player.get_walkforce()
    }
    player.get_phobj().hforce += hforce
  }
  if not(player.get_phobj().enablejd) {
    player.get_phobj().set_flag(PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
pub fn update_state(self : PlayerWalkState, player : Player) -> Unit {
  if player.get_phobj().onground {
    if not(self.haswalkinput(player)) ||
      player.get_phobj().moving_object.hspeed == 0.0 {
      player.set_state(CharState::STAND)
    }
  } else {
    player.set_state(CharState::FALL)
  }
}

///|
struct PlayerFallState {} derive(Default)

///|
pub fn initialize(self : PlayerFallState, player : Player) -> Unit {
  player.get_phobj().t = @physics.PhysicsObjectType::NORMAL
}

///|
pub fn send_action(
  self : PlayerFallState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.ActionId::LEFT => player.set_direction(false)
      @keyboard.ActionId::RIGHT => player.set_direction(true)
      _ => ()
    }
  }
}

///|
pub fn update(self : PlayerFallState, player : Player) -> Unit {
  let hspeed = player.get_phobj().moving_object.hspeed
  if player.is_key_down(@keyboard.ActionId::LEFT) && hspeed > 0.0 {
    player.get_phobj().moving_object.hspeed -= 0.025
    if player.get_phobj().moving_object.hspeed < 0.0 {
      player.get_phobj().moving_object.hspeed = 0.0
    }
  } else if player.is_key_down(@keyboard.ActionId::RIGHT) && hspeed < 0.0 {
    player.get_phobj().moving_object.hspeed += 0.025
    if player.get_phobj().moving_object.hspeed > 0.0 {
      player.get_phobj().moving_object.hspeed = 0.0
    }
  }
}

///|
pub fn update_state(self : PlayerFallState, player : Player) -> Unit {
  if player.get_phobj().onground {
    if player.is_key_down(@keyboard.ActionId::LEFT) {
      player.set_direction(false)
      player.set_state(CharState::WALK)
    } else if player.is_key_down(@keyboard.ActionId::RIGHT) {
      player.set_direction(true)
      player.set_state(CharState::WALK)
    } else if player.is_key_down(@keyboard.ActionId::DOWN) {
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
pub fn initialize(self : PlayerProneState, player : Player) -> Unit {

}

///|
pub fn update_state(self : PlayerProneState, player : Player) -> Unit {

}

///|
pub fn send_action(
  self : PlayerProneState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.ActionId::JUMP =>
        if player.get_phobj().enablejd &&
          player.is_key_down(@keyboard.ActionId::DOWN) {
          play_jumpsound()
          player.get_phobj().moving_object.set_y(player.get_phobj().groundbelow)
          player.set_state(CharState::FALL)
        }
      _ => ()
    }
  } else {
    match ka {
      @keyboard.ActionId::DOWN => player.set_state(CharState::STAND)
      _ => ()
    }
  }
}

///|
pub fn update(self : PlayerProneState, player : Player) -> Unit {
  if not(player.get_phobj().enablejd) {
    player.get_phobj().set_flag(PhysicsObjectFlag::CHECK_BELOW)
  }
}

///|
struct PlayerSitState {} derive(Default)

///|
pub fn initialize(self : PlayerSitState, _player : Player) -> Unit {

}

///|
pub fn update(self : PlayerSitState, _player : Player) -> Unit {

}

///|
pub fn update_state(self : PlayerSitState, _player : Player) -> Unit {

}

///|
pub fn send_action(
  self : PlayerSitState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.ActionId::LEFT => {
        player.set_direction(false)
        player.set_state(CharState::WALK)
      }
      @keyboard.ActionId::RIGHT => {
        player.set_direction(true)
        player.set_state(CharState::WALK)
      }
      @keyboard.ActionId::JUMP => {
        play_jumpsound()
        player.set_state(CharState::STAND)
      }
      @keyboard.ActionId::UP => player.set_state(CharState::STAND)
      _ => ()
    }
  }
}

///|
struct PlayerFlyState {} derive(Default)

///|
pub fn initialize(self : PlayerFlyState, player : Player) -> Unit {
  player.get_phobj().t = if player.is_underwater() {
    @physics.PhysicsObjectType::SWIMMING
  } else {
    @physics.PhysicsObjectType::FLYING
  }
}

///|
pub fn send_action(
  self : PlayerFlyState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.ActionId::LEFT => player.set_direction(false)
      @keyboard.ActionId::RIGHT => player.set_direction(true)
      _ => ()
    }
  }
}

///|
pub fn update(self : PlayerFlyState, player : Player) -> Unit {
  if player.is_attacking() {
    return
  }
  if player.is_key_down(@keyboard.ActionId::LEFT) {
    player.get_phobj().hforce = -player.get_flyforce()
  } else if player.is_key_down(@keyboard.ActionId::RIGHT) {
    player.get_phobj().hforce = player.get_flyforce()
  }
  if player.is_key_down(@keyboard.ActionId::UP) {
    player.get_phobj().vforce = -player.get_flyforce()
  } else if player.is_key_down(@keyboard.ActionId::DOWN) {
    player.get_phobj().vforce = player.get_flyforce()
  }
}

///|
pub fn update_state(self : PlayerFlyState, player : Player) -> Unit {
  if player.get_phobj().onground && player.is_underwater() {
    let state = if player.is_key_down(@keyboard.ActionId::LEFT) {
      player.set_direction(false)
      CharState::WALK
    } else if player.is_key_down(@keyboard.ActionId::RIGHT) {
      player.set_direction(true)
      CharState::WALK
    } else if player.is_key_down(@keyboard.ActionId::DOWN) {
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
pub fn initialize(self : PlayerClimbState, player : Player) -> Unit {
  player.get_phobj().t = @physics.PhysicsObjectType::FIXATED
}

///|
pub fn send_action(
  self : PlayerClimbState,
  player : Player,
  ka : @keyboard.ActionId,
  down : Bool
) -> Unit {
  if down {
    match ka {
      @keyboard.ActionId::JUMP =>
        if player.is_key_down(@keyboard.ActionId::LEFT) {
          play_jumpsound()
          player.set_direction(false)
          player.get_phobj().moving_object.hspeed = -player.get_walkforce() *
            8.0
          player.get_phobj().moving_object.vspeed = -player.get_jumpforce() /
            1.5
          self.cancel_ladder(player)
        } else if player.is_key_down(@keyboard.ActionId::RIGHT) {
          play_jumpsound()
          player.set_direction(true)
          player.get_phobj().moving_object.hspeed = player.get_walkforce() * 8.0
          player.get_phobj().moving_object.vspeed = -player.get_jumpforce() /
            1.5
          self.cancel_ladder(player)
        }
      _ => ()
    }
  }
}

///|
pub fn update(self : PlayerClimbState, player : Player) -> Unit {
  if player.is_key_down(@keyboard.ActionId::UP) {
    player.get_phobj().set_vspeed(-player.get_climbforce())
  } else if player.is_key_down(@keyboard.ActionId::DOWN) {
    player.get_phobj().set_vspeed(player.get_climbforce())
  } else {
    player.get_phobj().set_vspeed(0.0)
  }
}

///|
pub fn update_state(self : PlayerClimbState, player : Player) -> Unit {
  let y = player.get_phobj().get_y()
  let downwards = player.is_key_down(@keyboard.ActionId::DOWN)
  match player.get_ladder() {
    Some(ladder) =>
      if ladder.felloff(y, downwards) {
        self.cancel_ladder(player)
      }
    None => ()
  }
}

///|
pub fn cancel_ladder(self : PlayerClimbState, player : Player) -> Unit {
  player.set_state(CharState::FALL)
  player.set_ladder(None)
}
