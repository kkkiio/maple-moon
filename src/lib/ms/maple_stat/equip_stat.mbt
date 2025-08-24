///|
pub(all) enum EquipStatId {
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
pub fn EquipStatId::int_value(self : EquipStatId) -> Int {
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
pub impl Hash for EquipStatId with hash_combine(
  self : EquipStatId,
  hasher : Hasher
) -> Unit {
  hasher.combine(self.int_value())
}
// pub impl Show for EquipStatId with output(self : EquipStatId, logger : &Logger) -> Unit {
//   let str = match self {
//     STR => "STR"
//     DEX => "DEX"
//     INT => "INT"
//     LUK => "LUK"
//     HP => "MaxHP"
//     MP => "MaxMP"
//     WATK => "Attack Power"
//     MAGIC => "Magic Attack"
//     WDEF => "Defense"
//     MDEF => "MAGIC DEFENSE"
//     ACC => "ACCURACY"
//     AVOID => "AVOID"
//     HANDS => "HANDS"
//     SPEED => "Speed"
//     JUMP => "Jump"
//   }
//   logger.write_string(str)
// }

///|
pub fn EquipStatId::name(self : EquipStatId) -> String {
  match self {
    STR => "STR"
    DEX => "DEX"
    INT => "INT"
    LUK => "LUK"
    HP => "HP"
    MP => "MP"
    WATK => "WATK"
    MAGIC => "MAGIC"
    WDEF => "WDEF"
    MDEF => "MDEF"
    ACC => "ACC"
    AVOID => "AVOID"
    HANDS => "HANDS"
    SPEED => "SPEED"
    JUMP => "JUMP"
  }
}

///|
pub fn EquipStatId::from_name(name : String) -> EquipStatId? {
  let id = match name {
    "STR" => EquipStatId::STR
    "DEX" => EquipStatId::DEX
    "INT" => EquipStatId::INT
    "LUK" => EquipStatId::LUK
    "HP" => EquipStatId::HP
    "MP" => EquipStatId::MP
    "WATK" => EquipStatId::WATK
    "MAGIC" => EquipStatId::MAGIC
    "WDEF" => EquipStatId::WDEF
    "MDEF" => EquipStatId::MDEF
    "ACC" => EquipStatId::ACC
    "AVOID" => EquipStatId::AVOID
    "HANDS" => EquipStatId::HANDS
    "SPEED" => EquipStatId::SPEED
    "JUMP" => EquipStatId::JUMP
    _ => return None
  }
  Some(id)
}

///|
pub impl Show for EquipStatId with output(self : EquipStatId, logger : &Logger) -> Unit {
  logger.write_string(self.name())
}

///|
pub let all_equip_stats : FixedArray[EquipStatId] = [
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
