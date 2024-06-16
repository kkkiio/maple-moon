pub enum Id {
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
} derive(Debug, Eq, Compare)

pub fn int_value(self : Id) -> Int {
  match self {
    Id::NONE => 0
    Id::ALERT => 1
    Id::DEAD => 2
    Id::FLY => 3
    Id::HEAL => 4
    Id::JUMP => 5
    Id::LADDER => 6
    Id::PRONE => 7
    Id::PRONESTAB => 8
    Id::ROPE => 9
    Id::SHOT => 10
    Id::SHOOT1 => 11
    Id::SHOOT2 => 12
    Id::SHOOTF => 13
    Id::SIT => 14
    Id::STABO1 => 15
    Id::STABO2 => 16
    Id::STABOF => 17
    Id::STABT1 => 18
    Id::STABT2 => 19
    Id::STABTF => 20
    Id::STAND1 => 21
    Id::STAND2 => 22
    Id::SWINGO1 => 23
    Id::SWINGO2 => 24
    Id::SWINGO3 => 25
    Id::SWINGOF => 26
    Id::SWINGP1 => 27
    Id::SWINGP2 => 28
    Id::SWINGPF => 29
    Id::SWINGT1 => 30
    Id::SWINGT2 => 31
    Id::SWINGT3 => 32
    Id::SWINGTF => 33
    Id::WALK1 => 34
    Id::WALK2 => 35
  }
}

pub fn hash(self : Id) -> Int {
  self.int_value()
}

pub fn Id::default() -> Id {
  NONE
}

pub fn by_state(state : Int) -> Id {
  let index = state / 2 - 1
  if index < 0 || index > 10 {
    return Id::WALK1
  }
  let state_values = [
    Id::WALK1,
    Id::STAND1,
    Id::JUMP,
    Id::ALERT,
    Id::PRONE,
    Id::FLY,
    Id::LADDER,
    Id::ROPE,
    Id::DEAD,
    Id::SIT,
  ]
  return state_values[index]
}

let int_id_map : @immut/sorted_map.Map[Int, Id] = @immut/sorted_map.from_array(
  [
    (0, Id::NONE),
    (1, Id::ALERT),
    (2, Id::DEAD),
    (3, Id::FLY),
    (4, Id::HEAL),
    (5, Id::JUMP),
    (6, Id::LADDER),
    (7, Id::PRONE),
    (8, Id::PRONESTAB),
    (9, Id::ROPE),
    (10, Id::SHOT),
    (11, Id::SHOOT1),
    (12, Id::SHOOT2),
    (13, Id::SHOOTF),
    (14, Id::SIT),
    (15, Id::STABO1),
    (16, Id::STABO2),
    (17, Id::STABOF),
    (18, Id::STABT1),
    (19, Id::STABT2),
    (20, Id::STABTF),
    (21, Id::STAND1),
    (22, Id::STAND2),
    (23, Id::SWINGO1),
    (24, Id::SWINGO2),
    (25, Id::SWINGO3),
    (26, Id::SWINGOF),
    (27, Id::SWINGP1),
    (28, Id::SWINGP2),
    (29, Id::SWINGPF),
    (30, Id::SWINGT1),
    (31, Id::SWINGT2),
    (32, Id::SWINGT3),
    (33, Id::SWINGTF),
    (34, Id::WALK1),
    (35, Id::WALK2),
  ],
)

pub fn by_id(id : Int) -> Id {
  int_id_map[id].unwrap()
}

pub fn is_climbing(value : Id) -> Bool {
  return value == Id::LADDER || value == Id::ROPE
}

pub fn baseof(value : Id) -> Id {
  match value {
    Id::STAND2 => Id::STAND1
    Id::WALK2 => Id::WALK1
    _ => value
  }
}

pub fn secondof(value : Id) -> Id {
  match value {
    Id::STAND1 => Id::STAND2
    Id::WALK1 => Id::WALK2
    _ => value
  }
}

pub let names : @immut/sorted_map.Map[String, Id] = @immut/sorted_map.from_array(
  [
    ("", Id::NONE),
    ("alert", Id::ALERT),
    ("dead", Id::DEAD),
    ("fly", Id::FLY),
    ("heal", Id::HEAL),
    ("jump", Id::JUMP),
    ("ladder", Id::LADDER),
    ("prone", Id::PRONE),
    ("proneStab", Id::PRONESTAB),
    ("rope", Id::ROPE),
    ("shot", Id::SHOT),
    ("shoot1", Id::SHOOT1),
    ("shoot2", Id::SHOOT2),
    ("shootF", Id::SHOOTF),
    ("sit", Id::SIT),
    ("stabO1", Id::STABO1),
    ("stabO2", Id::STABO2),
    ("stabOF", Id::STABOF),
    ("stabT1", Id::STABT1),
    ("stabT2", Id::STABT2),
    ("stabTF", Id::STABTF),
    ("stand1", Id::STAND1),
    ("stand2", Id::STAND2),
    ("swingO1", Id::SWINGO1),
    ("swingO2", Id::SWINGO2),
    ("swingO3", Id::SWINGO3),
    ("swingOF", Id::SWINGOF),
    ("swingP1", Id::SWINGP1),
    ("swingP2", Id::SWINGP2),
    ("swingPF", Id::SWINGPF),
    ("swingT1", Id::SWINGT1),
    ("swingT2", Id::SWINGT2),
    ("swingT3", Id::SWINGT3),
    ("swingTF", Id::SWINGTF),
    ("walk1", Id::WALK1),
    ("walk2", Id::WALK2),
  ],
)

pub fn by_string(name : String) -> Id {
  names[name].unwrap()
}
