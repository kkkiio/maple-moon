pub(all) enum StanceId {
  NONE
  ALERT
  DEAD
  FLY
  HEAL
  JUMP
  LADDER
  PRONE
  PRONESTAB
  ROPE
  SHOT
  SHOOT1
  SHOOT2
  SHOOTF
  SIT
  STABO1
  STABO2
  STABOF
  STABT1
  STABT2
  STABTF
  STAND1
  STAND2
  SWINGO1
  SWINGO2
  SWINGO3
  SWINGOF
  SWINGP1
  SWINGP2
  SWINGPF
  SWINGT1
  SWINGT2
  SWINGT3
  SWINGTF
  WALK1
  WALK2
} derive(Eq, Compare)

pub fn int_value(self : StanceId) -> Int {
  match self {
    StanceId::NONE => 0
    StanceId::ALERT => 1
    StanceId::DEAD => 2
    StanceId::FLY => 3
    StanceId::HEAL => 4
    StanceId::JUMP => 5
    StanceId::LADDER => 6
    StanceId::PRONE => 7
    StanceId::PRONESTAB => 8
    StanceId::ROPE => 9
    StanceId::SHOT => 10
    StanceId::SHOOT1 => 11
    StanceId::SHOOT2 => 12
    StanceId::SHOOTF => 13
    StanceId::SIT => 14
    StanceId::STABO1 => 15
    StanceId::STABO2 => 16
    StanceId::STABOF => 17
    StanceId::STABT1 => 18
    StanceId::STABT2 => 19
    StanceId::STABTF => 20
    StanceId::STAND1 => 21
    StanceId::STAND2 => 22
    StanceId::SWINGO1 => 23
    StanceId::SWINGO2 => 24
    StanceId::SWINGO3 => 25
    StanceId::SWINGOF => 26
    StanceId::SWINGP1 => 27
    StanceId::SWINGP2 => 28
    StanceId::SWINGPF => 29
    StanceId::SWINGT1 => 30
    StanceId::SWINGT2 => 31
    StanceId::SWINGT3 => 32
    StanceId::SWINGTF => 33
    StanceId::WALK1 => 34
    StanceId::WALK2 => 35
  }
}

pub fn hash(self : StanceId) -> Int {
  self.int_value()
}

pub fn StanceId::default() -> StanceId {
  NONE
}

pub fn StanceId::count() -> Int {
  36
}

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

let int_id_map : @immut/sorted_map.T[Int, StanceId] = @immut/sorted_map.from_array(
  [
    (0, StanceId::NONE),
    (1, StanceId::ALERT),
    (2, StanceId::DEAD),
    (3, StanceId::FLY),
    (4, StanceId::HEAL),
    (5, StanceId::JUMP),
    (6, StanceId::LADDER),
    (7, StanceId::PRONE),
    (8, StanceId::PRONESTAB),
    (9, StanceId::ROPE),
    (10, StanceId::SHOT),
    (11, StanceId::SHOOT1),
    (12, StanceId::SHOOT2),
    (13, StanceId::SHOOTF),
    (14, StanceId::SIT),
    (15, StanceId::STABO1),
    (16, StanceId::STABO2),
    (17, StanceId::STABOF),
    (18, StanceId::STABT1),
    (19, StanceId::STABT2),
    (20, StanceId::STABTF),
    (21, StanceId::STAND1),
    (22, StanceId::STAND2),
    (23, StanceId::SWINGO1),
    (24, StanceId::SWINGO2),
    (25, StanceId::SWINGO3),
    (26, StanceId::SWINGOF),
    (27, StanceId::SWINGP1),
    (28, StanceId::SWINGP2),
    (29, StanceId::SWINGPF),
    (30, StanceId::SWINGT1),
    (31, StanceId::SWINGT2),
    (32, StanceId::SWINGT3),
    (33, StanceId::SWINGTF),
    (34, StanceId::WALK1),
    (35, StanceId::WALK2),
  ],
)

pub fn StanceId::by_id(id : Int) -> StanceId {
  int_id_map[id].unwrap()
}

pub fn is_climbing(self : StanceId) -> Bool {
  return self == StanceId::LADDER || self == StanceId::ROPE
}

pub fn StanceId::baseof(value : StanceId) -> StanceId {
  match value {
    StanceId::STAND2 => StanceId::STAND1
    StanceId::WALK2 => StanceId::WALK1
    _ => value
  }
}

pub fn secondof(value : StanceId) -> StanceId {
  match value {
    StanceId::STAND1 => StanceId::STAND2
    StanceId::WALK1 => StanceId::WALK2
    _ => value
  }
}

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

pub fn StanceId::by_string(name : String) -> StanceId {
  stance_name_id_map[name].unwrap()
}

pub fn name(self : StanceId) -> String {
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

pub fn hash_combine(self : StanceId, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}
