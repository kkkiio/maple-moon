///|
pub(all) enum Id {
  SKIN = 0x1
  FACE = 0x2
  HAIR = 0x4
  LEVEL = 0x10
  JOB = 0x20
  STR = 0x40
  DEX = 0x80
  INT = 0x100
  LUK = 0x200
  HP = 0x400
  MAXHP = 0x800
  MP = 0x1000
  MAXMP = 0x2000
  AP = 0x4000
  SP = 0x8000
  EXP = 0x10000
  FAME = 0x20000
  /// base currency
  MESO = 0x40000
  PET = 0x180008
  GACHAEXP = 0x200000
} derive(Eq, Compare, Hash)

///|
pub fn Id::int_value(self : Id) -> Int = "%identity"

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
pub impl ToJson for Id with to_json(self) -> Json {
  Json::string(self.name())
}

///|
pub impl @json.FromJson for Id with from_json(json, path) -> Id {
  let name : String = @json.from_json(json, path=path.add_key("name"))
  Id::from_name(name).unwrap_or_error(
    @json.JsonDecodeError((path, "invalid stat name")),
  )
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
