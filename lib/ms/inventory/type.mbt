///|
pub(all) enum TypeId {
  EQUIP
  USE
  SETUP
  ETC
  CASH
  EQUIPPED
} derive(Eq, Hash, Show, ToJson)

///|
pub fn int_value(self : TypeId) -> Int {
  match self {
    TypeId::EQUIP => 1
    TypeId::USE => 2
    TypeId::SETUP => 3
    TypeId::ETC => 4
    TypeId::CASH => 5
    TypeId::EQUIPPED => 6
  }
}

///|
pub fn TypeId::by_item_id(item_id : Int) -> TypeId? {
  let prefix = item_id / 1000000
  match prefix {
    1 => TypeId::EQUIP |> Some
    2 => TypeId::USE |> Some
    3 => TypeId::SETUP |> Some
    4 => TypeId::ETC |> Some
    5 => TypeId::CASH |> Some
    _ => None
  }
}

///|
pub fn TypeId::by_value(value : Int) -> TypeId? {
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
