pub enum Id {
  STR
  DEX
  INT
  LUK
  HP
  MP
  WATK
  MAGIC
  WDEF
  // TODO: Does current GMS use these anymore?
  MDEF
  ACC
  AVOID
  HANDS
  SPEED
  JUMP
} derive(Eq)

pub let values : FixedArray[Id] = [
  STR,
  DEX,
  INT,
  LUK,
  HP,
  MP,
  WATK,
  MAGIC,
  WDEF,
  MDEF,
  ACC,
  AVOID,
  HANDS,
  SPEED,
  JUMP,
]

fn by_id(id : Int) -> Id {
  values[id]
}

fn value_of(value : Id) -> Int {
  value.int_value()
}

pub fn int_value(self : Id) -> Int {
  values.search(self).unwrap()
}

fn to_string(self : Id) -> String {
  match self {
    STR => "STR"
    DEX => "DEX"
    INT => "INT"
    LUK => "LUK"
    HP => "MaxHP"
    MP => "MaxMP"
    WATK => "Attack Power"
    MAGIC => "Magic Attack"
    WDEF => "Defense"
    MDEF => "MAGIC DEFENSE"
    ACC => "ACCURACY"
    AVOID => "AVOID"
    HANDS => "HANDS"
    SPEED => "Speed"
    JUMP => "Jump"
  }
}
