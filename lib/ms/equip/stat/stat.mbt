///|
pub(all) enum Id {
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
} derive(Eq, Compare)

///|
pub fn int_value(self : Id) -> Int {
  match self {
    STR => 0
    DEX => 1
    INT => 2
    LUK => 3
    HP => 4
    MP => 5
    WATK => 6
    MAGIC => 7
    WDEF => 8
    MDEF => 9
    ACC => 10
    AVOID => 11
    HANDS => 12
    SPEED => 13
    JUMP => 14
  }
}

///|
pub impl Hash for Id with hash_combine(self : Id, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub impl Show for Id with output(self : Id, logger : &Logger) -> Unit {
  let str = match self {
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
  logger.write_string(str)
}

///|
pub let all_stats : FixedArray[Id] = [
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
