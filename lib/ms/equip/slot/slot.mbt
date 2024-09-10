pub enum Id {
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
} derive(Eq)

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

pub fn hash(self : Id) -> Int {
  self.int_value()
}

pub fn hash_combine(self : Id, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub fn Id::length() -> Int {
  62
}
