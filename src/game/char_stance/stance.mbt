///|
pub(all) enum StanceId {
  NONE = 0
  ALERT = 1
  DEAD = 2
  FLY = 3
  HEAL = 4
  JUMP = 5
  LADDER = 6
  PRONE = 7
  PRONESTAB = 8
  ROPE = 9
  SHOT = 10
  SHOOT1 = 11
  SHOOT2 = 12
  SHOOTF = 13
  SIT = 14
  STABO1 = 15
  STABO2 = 16
  STABOF = 17
  STABT1 = 18
  STABT2 = 19
  STABTF = 20
  STAND1 = 21
  STAND2 = 22
  SWINGO1 = 23
  SWINGO2 = 24
  SWINGO3 = 25
  SWINGOF = 26
  SWINGP1 = 27
  SWINGP2 = 28
  SWINGPF = 29
  SWINGT1 = 30
  SWINGT2 = 31
  SWINGT3 = 32
  SWINGTF = 33
  WALK1 = 34
  WALK2 = 35
} derive(Eq, Compare, Hash, Debug)

///|
pub impl Show for StanceId with fn output(self, logger) {
  logger.write_string(self.name())
}

///|
pub impl ToJson for StanceId with fn to_json(self) {
  self.to_string().to_json()
}

///|
pub fn StanceId::int_value(self : StanceId) -> Int = "%identity"

///|
pub impl Default for StanceId with fn default() -> StanceId {
  StanceId::NONE
}

///|
pub fn StanceId::count() -> Int {
  36
}

///|
pub fn StanceId::by_state(state : Int) -> StanceId {
  let index = state / 2 - 1
  if index < 0 || index > 10 {
    return StanceId::WALK1
  }
  let state_values = [
    StanceId::WALK1,
    StanceId::STAND1,
    StanceId::JUMP,
    StanceId::ALERT,
    StanceId::PRONE,
    StanceId::FLY,
    StanceId::LADDER,
    StanceId::ROPE,
    StanceId::DEAD,
    StanceId::SIT,
  ]
  return state_values[index]
}

///|
pub fn StanceId::is_climbing(self : StanceId) -> Bool {
  return self == StanceId::LADDER || self == StanceId::ROPE
}

///|
pub fn StanceId::is_attack(self : StanceId) -> Bool {
  match self {
    StanceId::SHOT | StanceId::SHOOT1 | StanceId::SHOOT2 | StanceId::SHOOTF =>
      true
    StanceId::STABO1 | StanceId::STABO2 | StanceId::STABOF => true
    StanceId::STABT1 | StanceId::STABT2 | StanceId::STABTF => true
    StanceId::SWINGO1
    | StanceId::SWINGO2
    | StanceId::SWINGO3
    | StanceId::SWINGOF => true
    StanceId::SWINGP1 | StanceId::SWINGP2 | StanceId::SWINGPF => true
    StanceId::SWINGT1
    | StanceId::SWINGT2
    | StanceId::SWINGT3
    | StanceId::SWINGTF => true
    StanceId::PRONESTAB => true
    _ => false
  }
}

///|
pub fn StanceId::baseof(value : StanceId) -> StanceId {
  match value {
    StanceId::STAND2 => StanceId::STAND1
    StanceId::WALK2 => StanceId::WALK1
    _ => value
  }
}

///|
pub fn secondof(value : StanceId) -> StanceId {
  match value {
    StanceId::STAND1 => StanceId::STAND2
    StanceId::WALK1 => StanceId::WALK2
    _ => value
  }
}

///|
pub let stance_name_id_map : Map[String, StanceId] = {
  "": StanceId::NONE,
  "alert": StanceId::ALERT,
  "dead": StanceId::DEAD,
  "fly": StanceId::FLY,
  "heal": StanceId::HEAL,
  "jump": StanceId::JUMP,
  "ladder": StanceId::LADDER,
  "prone": StanceId::PRONE,
  "proneStab": StanceId::PRONESTAB,
  "rope": StanceId::ROPE,
  "shot": StanceId::SHOT,
  "shoot1": StanceId::SHOOT1,
  "shoot2": StanceId::SHOOT2,
  "shootF": StanceId::SHOOTF,
  "sit": StanceId::SIT,
  "stabO1": StanceId::STABO1,
  "stabO2": StanceId::STABO2,
  "stabOF": StanceId::STABOF,
  "stabT1": StanceId::STABT1,
  "stabT2": StanceId::STABT2,
  "stabTF": StanceId::STABTF,
  "stand1": StanceId::STAND1,
  "stand2": StanceId::STAND2,
  "swingO1": StanceId::SWINGO1,
  "swingO2": StanceId::SWINGO2,
  "swingO3": StanceId::SWINGO3,
  "swingOF": StanceId::SWINGOF,
  "swingP1": StanceId::SWINGP1,
  "swingP2": StanceId::SWINGP2,
  "swingPF": StanceId::SWINGPF,
  "swingT1": StanceId::SWINGT1,
  "swingT2": StanceId::SWINGT2,
  "swingT3": StanceId::SWINGT3,
  "swingTF": StanceId::SWINGTF,
  "walk1": StanceId::WALK1,
  "walk2": StanceId::WALK2,
}

///|
pub fn StanceId::from_name(name : String) -> StanceId? {
  stance_name_id_map.get(name)
}

///|
pub fn StanceId::name(self : StanceId) -> String {
  match self {
    StanceId::NONE => ""
    StanceId::ALERT => "alert"
    StanceId::DEAD => "dead"
    StanceId::FLY => "fly"
    StanceId::HEAL => "heal"
    StanceId::JUMP => "jump"
    StanceId::LADDER => "ladder"
    StanceId::PRONE => "prone"
    StanceId::PRONESTAB => "proneStab"
    StanceId::ROPE => "rope"
    StanceId::SHOT => "shot"
    StanceId::SHOOT1 => "shoot1"
    StanceId::SHOOT2 => "shoot2"
    StanceId::SHOOTF => "shootF"
    StanceId::SIT => "sit"
    StanceId::STABO1 => "stabO1"
    StanceId::STABO2 => "stabO2"
    StanceId::STABOF => "stabOF"
    StanceId::STABT1 => "stabT1"
    StanceId::STABT2 => "stabT2"
    StanceId::STABTF => "stabTF"
    StanceId::STAND1 => "stand1"
    StanceId::STAND2 => "stand2"
    StanceId::SWINGO1 => "swingO1"
    StanceId::SWINGO2 => "swingO2"
    StanceId::SWINGO3 => "swingO3"
    StanceId::SWINGOF => "swingOF"
    StanceId::SWINGP1 => "swingP1"
    StanceId::SWINGP2 => "swingP2"
    StanceId::SWINGPF => "swingPF"
    StanceId::SWINGT1 => "swingT1"
    StanceId::SWINGT2 => "swingT2"
    StanceId::SWINGT3 => "swingT3"
    StanceId::SWINGTF => "swingTF"
    StanceId::WALK1 => "walk1"
    StanceId::WALK2 => "walk2"
  }
}
