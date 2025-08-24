///|
pub(all) enum Mapping {
  SKILL(Int)
  ITEM(Int)
  CASH(Int)
  MENU(BasicActionId)
  ACTION(BasicActionId)
  FACE(Int)
  MACRO(Int)
  TEXT(Int)
} derive(Eq, Show, Hash)

///|
pub fn Mapping::to_enum_value(self : Mapping) -> (Int, Int) {
  match self {
    SKILL(v) => (1, v)
    ITEM(v) => (2, v)
    CASH(v) => (3, v)
    MENU(v) => (4, v.int_value())
    ACTION(v) => (5, v.int_value())
    FACE(v) => (6, v)
    MACRO(v) => (7, v)
    TEXT(v) => (8, v)
  }
}

///|
pub fn Mapping::from_int_enum(type_id : Int, value : Int) -> Mapping? {
  let res = match type_id {
    1 => SKILL(value)
    2 => ITEM(value)
    3 => CASH(value)
    4 =>
      if BasicActionId::from_int(value) is Some(v) {
        MENU(v)
      } else {
        return None
      }
    5 =>
      if BasicActionId::from_int(value) is Some(v) {
        ACTION(v)
      } else {
        return None
      }
    6 => FACE(value)
    7 => MACRO(value)
    8 => TEXT(value)
    _ => return None
  }
  Some(res)
}

///|
pub fn Mapping::to_name_value(self : Mapping) -> (String, Int) {
  match self {
    SKILL(v) => ("SKILL", v)
    ITEM(v) => ("ITEM", v)
    CASH(v) => ("CASH", v)
    MENU(v) => ("MENU", v.int_value())
    ACTION(v) => ("ACTION", v.int_value())
    FACE(v) => ("FACE", v)
    MACRO(v) => ("MACRO", v)
    TEXT(v) => ("TEXT", v)
  }
}

///|
pub fn Mapping::from_name_value(name : String, value : Int) -> Mapping? {
  let res = match name {
    "SKILL" => SKILL(value)
    "ITEM" => ITEM(value)
    "CASH" => CASH(value)
    "MENU" =>
      if BasicActionId::from_int(value) is Some(v) {
        MENU(v)
      } else {
        return None
      }
    "ACTION" =>
      if BasicActionId::from_int(value) is Some(v) {
        ACTION(v)
      } else {
        return None
      }
    "FACE" => FACE(value)
    "MACRO" => MACRO(value)
    "TEXT" => TEXT(value)
    _ => return None
  }
  Some(res)
}

///|
pub fn Mapping::get_action_value(self : Mapping) -> Int {
  self.to_enum_value().1
}
