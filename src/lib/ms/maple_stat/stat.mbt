///|
pub(all) enum Id {
  SKIN
  FACE
  HAIR
  LEVEL
  JOB
  STR
  DEX
  INT
  LUK
  HP
  MAXHP
  MP
  MAXMP
  AP
  SP
  EXP
  FAME
  MESO // base currency
  PET
  GACHAEXP
} derive(Eq, Hash)

///|
pub fn Id::int_value(self : Id) -> Int {
  match self {
    Id::SKIN => 0x1
    Id::FACE => 0x2
    Id::HAIR => 0x4
    Id::LEVEL => 0x10
    Id::JOB => 0x20
    Id::STR => 0x40
    Id::DEX => 0x80
    Id::INT => 0x100
    Id::LUK => 0x200
    Id::HP => 0x400
    Id::MAXHP => 0x800
    Id::MP => 0x1000
    Id::MAXMP => 0x2000
    Id::AP => 0x4000
    Id::SP => 0x8000
    Id::EXP => 0x10000
    Id::FAME => 0x20000
    Id::MESO => 0x40000
    Id::PET => 0x180008
    Id::GACHAEXP => 0x200000
  }
}

///|
pub impl Compare for Id with compare(self, other) -> Int {
  self.int_value().compare(other.int_value())
}

///|
pub fn Id::name(self : Id) -> String {
  match self {
    Id::PET => "PET"
    Id::MESO => "MESO"
    Id::FAME => "FAME"
    Id::EXP => "EXP"
    Id::SP => "SP"
    Id::AP => "AP"
    Id::MAXMP => "MAXMP"
    Id::MP => "MP"
    Id::MAXHP => "MAXHP"
    Id::HP => "HP"
    Id::LUK => "LUK"
    Id::INT => "INT"
    Id::DEX => "DEX"
    Id::STR => "STR"
    Id::JOB => "JOB"
    Id::LEVEL => "LEVEL"
    Id::HAIR => "HAIR"
    Id::FACE => "FACE"
    Id::SKIN => "SKIN"
    Id::GACHAEXP => "GACHAEXP"
  }
}

///|
pub fn Id::from_name(name : String) -> Id? {
  let id = match name {
    "PET" => Id::PET
    "MESO" => Id::MESO
    "FAME" => Id::FAME
    "EXP" => Id::EXP
    "SP" => Id::SP
    "AP" => Id::AP
    "MAXMP" => Id::MAXMP
    "MP" => Id::MP
    "MAXHP" => Id::MAXHP
    "HP" => Id::HP
    "LUK" => Id::LUK
    "INT" => Id::INT
    "DEX" => Id::DEX
    "STR" => Id::STR
    "JOB" => Id::JOB
    "LEVEL" => Id::LEVEL
    "HAIR" => Id::HAIR
    "FACE" => Id::FACE
    "SKIN" => Id::SKIN
    "GACHAEXP" => Id::GACHAEXP
    _ => return None
  }
  Some(id)
}

///|
pub impl Show for Id with output(self, logger) -> Unit {
  logger.write_string(self.name())
}

///|
pub let all_stats : Array[Id] = [
  SKIN,
  FACE,
  HAIR,
  LEVEL,
  JOB,
  STR,
  DEX,
  INT,
  LUK,
  HP,
  MAXHP,
  MP,
  MAXMP,
  AP,
  SP,
  EXP,
  FAME,
  MESO,
  PET,
  GACHAEXP,
]
