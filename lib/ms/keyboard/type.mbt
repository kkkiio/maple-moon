///|
pub(all) enum KeyType {
  SKILL
  ITEM
  CASH
  MENU
  ACTION
  FACE
  MACRO
  TEXT
} derive(Eq)

///|
pub fn KeyType::int_value(self : KeyType) -> Int {
  match self {
    SKILL => 1
    ITEM => 2
    CASH => 3
    MENU => 4
    ACTION => 5
    FACE => 6
    MACRO => 7
    TEXT => 8
  }
}

///|
pub fn KeyType::from_int(id : Int) -> KeyType? {
  match id {
    1 => Some(SKILL)
    2 => Some(ITEM)
    3 => Some(CASH)
    4 => Some(MENU)
    5 => Some(ACTION)
    6 => Some(FACE)
    7 => Some(MACRO)
    8 => Some(TEXT)
    _ => None
  }
}

///|
pub impl Hash for KeyType with hash_combine(self : KeyType, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub fn KeyType::name(self : KeyType) -> String {
  match self {
    SKILL => "SKILL"
    ITEM => "ITEM"
    CASH => "CASH"
    MENU => "MENU"
    ACTION => "ACTION"
    FACE => "FACE"
    MACRO => "MACRO"
    TEXT => "TEXT"
  }
}

///|
pub fn KeyType::from_name(name : String) -> KeyType? {
  match name {
    "SKILL" => Some(SKILL)
    "ITEM" => Some(ITEM)
    "CASH" => Some(CASH)
    "MENU" => Some(MENU)
    "ACTION" => Some(ACTION)
    "FACE" => Some(FACE)
    "MACRO" => Some(MACRO)
    "TEXT" => Some(TEXT)
    _ => None
  }
}

///|
pub impl Show for KeyType with output(self, logger) {
  logger.write_string(self.name())
}
