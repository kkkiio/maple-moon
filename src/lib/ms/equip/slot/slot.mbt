///|
pub(all) enum Id {
  NONE
  HAT
  FACE
  EYE_ACC
  EARACC
  TOP
  BOTTOM
  SHOES
  GLOVES
  CAPE
  SHIELD // TODO: Where is this now?
  WEAPON
  RING1
  RING2
  RING3
  RING4
  PENDANT1
  TAMEDMOB // TODO: Where is this now?
  SADDLE // TODO: Where is this now?
  MEDAL
  BELT
  POCKET // TODO: What is the proper value for this?
  BOOK // TODO: What is the proper value for this?
  PENDANT2 // TODO: What is the proper value for this?
  SHOULDER // TODO: What is the proper value for this?
  ANDROID_ // TODO: What is the proper value for this?
  EMBLEM // TODO: What is the proper value for this?
  BADGE // TODO: What is the proper value for this?
  SUBWEAPON // TODO: What is the proper value for this?
  HEART // TODO: What is the proper value for this?
  TOP_DEFAULT
  BOTTOM_DEFAULT
} derive(Eq, Show)

///|
pub impl ToJson for Id with to_json(self) -> Json {
  self.to_string().to_json()
}

///|
pub fn int_value(self : Id) -> Int {
  match self {
    NONE => 0
    HAT => 1
    FACE => 2
    EYE_ACC => 3
    EARACC => 4
    TOP => 5
    BOTTOM => 6
    SHOES => 7
    GLOVES => 8
    CAPE => 9
    SHIELD => 10
    WEAPON => 11
    RING1 => 12
    RING2 => 13
    RING3 => 15
    RING4 => 16
    PENDANT1 => 17
    TAMEDMOB => 18
    SADDLE => 19
    MEDAL => 49
    BELT => 50
    POCKET => 51
    BOOK => 52
    PENDANT2 => 53
    SHOULDER => 54
    ANDROID_ => 55
    EMBLEM => 56
    BADGE => 57
    SUBWEAPON => 58
    HEART => 59
    TOP_DEFAULT => 60
    BOTTOM_DEFAULT => 61
  }
}

///|
pub impl Hash for Id with hash_combine(self : Id, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

///|
pub fn Id::length() -> Int {
  62
}

///|
pub fn Id::from_int(slot : Int) -> Id {
  match slot {
    0 => NONE
    1 => HAT
    2 => FACE
    3 => EYE_ACC
    4 => EARACC
    5 => TOP
    6 => BOTTOM
    7 => SHOES
    8 => GLOVES
    9 => CAPE
    10 => SHIELD
    11 => WEAPON
    12 => RING1
    13 => RING2
    15 => RING3
    16 => RING4
    17 => PENDANT1
    18 => TAMEDMOB
    19 => SADDLE
    49 => MEDAL
    50 => BELT
    51 => POCKET
    52 => BOOK
    53 => PENDANT2
    54 => SHOULDER
    55 => ANDROID_
    56 => EMBLEM
    57 => BADGE
    58 => SUBWEAPON
    59 => HEART
    60 => TOP_DEFAULT
    61 => BOTTOM_DEFAULT
    _ => NONE
  }
}
