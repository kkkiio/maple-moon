// app/src/main/cpp/src/Character/Inventory/Weapon.h
// app/src/main/cpp/src/Character/Inventory/Weapon.cpp
pub enum Type {
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
} derive(Eq)

let values : FixedArray[(Type, Int)] = [
  (NONE, 0),
  (SWORD_1H, 130),
  (AXE_1H, 131),
  (MACE_1H, 132),
  (DAGGER, 133),
  (WAND, 137),
  (STAFF, 138),
  (SWORD_2H, 140),
  (AXE_2H, 141),
  (MACE_2H, 142),
  (SPEAR, 143),
  (POLEARM, 144),
  (BOW, 145),
  (CROSSBOW, 146),
  (CLAW, 147),
  (KNUCKLE, 148),
  (GUN, 149),
  (CASH, 170),
]

pub fn by_value(value : Int) -> Type {
  let r = values.iter().find_first(fn(it) { it.1 == value }).map(
    fn(it) { it.0 },
  )
  match r {
    Some(it) => it
    None => {
      println("Unknown weapon value=\(value)")
      NONE
    }
  }
}
