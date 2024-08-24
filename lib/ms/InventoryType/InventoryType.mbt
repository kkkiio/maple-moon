// app/src/main/cpp/src/Character/Inventory/InventoryType.h
// app/src/main/cpp/src/Character/Inventory/InventoryType.cpp
pub enum Id {
  NONE
  EQUIP
  USE
  SETUP
  ETC
  CASH
  EQUIPPED
} derive(Eq)

let values : FixedArray[(Id, Int)] = [
  (Id::EQUIPPED, -1),
  (Id::EQUIP, 1),
  (Id::USE, 2),
  (Id::SETUP, 3),
  (Id::ETC, 4),
  (Id::CASH, 5),
]

pub fn by_item_id(item_id : Int) -> Id {
  let prefix = item_id / 1000000
  if prefix > 0 {
    values
    .iter()
    .find_first(fn(it) { it.1 == item_id })
    .map(fn(it) { it.0 })
    .or(NONE)
  } else {
    Id::NONE
  }
}

pub fn by_value(value : Int) -> Id {
  // match value {
  //   -1 => Id::EQUIPPED
  //   1 => Id::EQUIP
  //   2 => Id::USE
  //   3 => Id::SETUP
  //   4 => Id::ETC
  //   5 => Id::CASH
  //   _ => {
  //     println("Unknown InventoryType::Id value: [", value, "]")
  //     Id::NONE
  //   }
  // }

  match
    values.iter().find_first(fn(it) { it.1 == value }).map(fn(it) { it.0 }) {
    Some(it) => it
    None => {
      println("Unknown InventoryType::Id value=\{value}")
      Id::NONE
    }
  }
}
