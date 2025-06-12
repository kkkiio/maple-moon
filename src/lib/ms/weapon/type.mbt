///|
pub(all) enum Type {
  NONE
  SWORD_1H
  AXE_1H
  MACE_1H
  DAGGER
  WAND
  STAFF
  SWORD_2H
  AXE_2H
  MACE_2H
  SPEAR
  POLEARM
  BOW
  CROSSBOW
  CLAW
  KNUCKLE
  GUN
  CASH
} derive(Eq, ToJson)

///|
pub fn int_value(self : Type) -> Int {
  match self {
    NONE => 0
    SWORD_1H => 130
    AXE_1H => 131
    MACE_1H => 132
    DAGGER => 133
    WAND => 137
    STAFF => 138
    SWORD_2H => 140
    AXE_2H => 141
    MACE_2H => 142
    SPEAR => 143
    POLEARM => 144
    BOW => 145
    CROSSBOW => 146
    CLAW => 147
    KNUCKLE => 148
    GUN => 149
    CASH => 170
  }
}

///|
pub(all) type! UnknownWeaponType Int derive(Show)

///|
pub fn Type::by_value(value : Int) -> Type!UnknownWeaponType {
  match value {
    0 => NONE
    130 => SWORD_1H
    131 => AXE_1H
    132 => MACE_1H
    133 => DAGGER
    137 => WAND
    138 => STAFF
    140 => SWORD_2H
    141 => AXE_2H
    142 => MACE_2H
    143 => SPEAR
    144 => POLEARM
    145 => BOW
    146 => CROSSBOW
    147 => CLAW
    148 => KNUCKLE
    149 => GUN
    170 => CASH
    _ => raise UnknownWeaponType(value)
  }
}
