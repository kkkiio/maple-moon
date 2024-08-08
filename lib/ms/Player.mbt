struct Player {
  char_base : CharBase
  stats : CharStats
  keys_down : Map[@KeyAction.Id, Bool]
  mut underwater : Bool
  mut last_move : Movement
}

pub typealias CharEntry = @login.CharEntry

// Construct a player object from the given character entry.
pub fn Player::from_entry(
  entry : CharEntry,
  wid : Int,
  channel_id : Int
) -> Player {
  let p = {
    char_base: CharBase::new(
      PlayerSub::default(),
      entry.id,
      CharLook::new(entry.look),
      entry.stats.name,
    ),
    stats: CharStats::from_entry(entry.stats),
    keys_down: Map::new(),
    underwater: false,
    last_move: Movement::default(),
  }
  p.set_state(CharState::STAND)
  p.set_direction(true)
  p
}

pub fn Player::default() -> Player {
  {
    char_base: CharBase::new(PlayerSub::default(), 0, CharLook::default(), ""),
    stats: CharStats::default(),
    underwater: false,
    keys_down: Map::new(),
    last_move: Movement::default(),
  }
}

pub fn get_position(self : Player) -> Point[Int] {
  self.char_base.get_position()
}

pub fn is_invincible(self : Player) -> Bool {
  true
}

pub fn update(self : Player, physics : Physics) -> Int {
  match get_player_state(self.char_base.state) {
    Some(pst) => {
      pst.update(self)
      physics.move_object(self.get_phobj())
      let aniend = self.char_base.update(
        physics,
        self.char_base.get_stancespeed(),
      )
      if aniend && self.char_base.attacking {
        self.char_base.attacking = false
        nullstate.update_state(self)
      } else {
        pst.update_state(self)
      }
    }
    None => ()
  }
  let stancebyte = self.char_base.state.int_value() + if self.char_base.facing_right {
      0
    } else {
      1
    }
  let newmove = Movement::from_physics_object(self.get_phobj(), stancebyte)
  let needupdate = self.last_move.hasmoved(newmove)
  if needupdate {
    // fn_move_player(newmove)
    self.last_move = newmove
  }
  self.char_base.get_layer()
}

// Respawn the player at the given position
pub fn respawn(self : Player, pos : Point[Int], underwater : Bool) -> Unit {
  self.set_position(pos.x, pos.y)
  self.underwater = underwater
}

pub fn set_position(self : Player, x : Int, y : Int) -> Unit {
  self.char_base.set_position({ x, y })
}

pub fn draw(
  self : Player,
  layer : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  if layer == self.char_base.get_layer() {
    self.char_base.draw(viewx, viewy, alpha)
  }
}

// Sends a Keyaction to the player's state, to apply forces, change the
// state and other behaviour.
pub fn send_action(self : Player, action : @KeyAction.Id, down : Bool) -> Unit {
  match get_player_state(self.char_base.state) {
    Some(pst) => pst.send_action(self, action, down)
    None => ()
  }
  self.keys_down[action] = down
}

struct PlayerStates {
  standing : PlayerStandState
  walking : PlayerWalkState
  falling : PlayerFallState
  lying : PlayerProneState
  // climbing : PlayerClimbState
  sitting : PlayerSitState
  flying : PlayerFlyState
} derive(Default)

let g_player_states : PlayerStates = PlayerStates::default()

fn get_player_state(state : CharState) -> PlayerState? {
  match state {
    CharState::STAND => Some(g_player_states.standing)
    CharState::WALK => Some(g_player_states.walking)
    CharState::FALL => Some(g_player_states.falling)
    CharState::PRONE => Some(g_player_states.lying)
    // CharState::LADDER=>
    // Some(g_player_states.climbing)
    CharState::SIT => Some(g_player_states.sitting)
    _ => None
  }
}

pub fn get_phobj(self : Player) -> PhysicsObject {
  self.char_base.get_phobj()
}

pub fn is_key_down(self : Player, key : @KeyAction.Id) -> Bool {
  self.keys_down[key].or(false)
}

pub fn set_direction(self : Player, flipped : Bool) -> Unit {
  if self.char_base.attacking.not() {
    self.char_base.set_direction(flipped)
  }
}

pub fn is_attacking(self : Player) -> Bool {
  self.char_base.attacking
}

// Set state ignore if attacking.
pub fn set_state(self : Player, st : CharState) -> Unit {
  if self.char_base.attacking.not() {
    self.char_base.set_state(st)
    match get_player_state(st) {
      Some(pst) => pst.initialize(self)
      None => ()
    }
  }
}

pub fn is_underwater(self : Player) -> Bool {
  self.underwater
}

pub fn get_flyforce(self : Player) -> Double {
  0.25
}

/// Returns the current jumping force, calculated from the total ES_JUMP stat.
pub fn get_jumpforce(self : Player) -> Double {
  1.0 + 3.5 * self.stats.get_total(@EquipStat.Id::JUMP).to_double() / 100.0
}

pub fn getflip(self : Player) -> Bool {
  self.char_base.getflip()
}

/// Returns the current walking force, calculated from the total ES_SPEED stat.
pub fn get_walkforce(self : Player) -> Double {
  0.05 + 0.11 * self.stats.get_total(@EquipStat.Id::SPEED).to_double() / 100.0
}

let nullstate : PlayerNullState = PlayerNullState::default()

struct PlayerSub {} derive(Default)

fn get_integer_attackspeed(self : PlayerSub) -> Int {
  0
  // let weapon_id = self.look.get_equips().get_weapon();

  // if weapon_id <= 0 {
  //   return 0;
  // }

  // let weapon = WeaponData::get(weapon_id);

  // let base_speed = self.stats.get_attackspeed();
  // let weapon_speed = weapon.get_speed();

  // base_speed + weapon_speed
}

pub fn get_stats(self : Player) -> CharStats {
  self.stats
}
