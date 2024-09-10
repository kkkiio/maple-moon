pub enum TypeId {
  EQUIP
  USE
  SETUP
  ETC
  CASH
  EQUIPPED
} derive(Eq, Hash)

let values : FixedArray[(TypeId, Int)] = [
  (TypeId::EQUIPPED, -1),
  (TypeId::EQUIP, 1),
  (TypeId::USE, 2),
  (TypeId::SETUP, 3),
  (TypeId::ETC, 4),
  (TypeId::CASH, 5),
]

pub fn by_item_id(item_id : Int) -> TypeId? {
  let prefix = item_id / 1000000
  if prefix > 0 {
    match prefix {
      1 => TypeId::EQUIP |> Some
      2 => TypeId::USE |> Some
      3 => TypeId::SETUP |> Some
      4 => TypeId::ETC |> Some
      5 => TypeId::CASH |> Some
    }
  } else {
    None
  }
}

pub fn by_value(value : Int) -> TypeId? {
  match value {
    -1 => TypeId::EQUIPPED |> Some
    1 => TypeId::EQUIP |> Some
    2 => TypeId::USE |> Some
    3 => TypeId::SETUP |> Some
    4 => TypeId::ETC |> Some
    5 => TypeId::CASH |> Some
    _ => None
  }
}
