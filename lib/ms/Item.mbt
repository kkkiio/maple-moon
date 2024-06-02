// app/src/main/cpp/src/Character/Inventory/Item.h
// app/src/main/cpp/src/Character/Inventory/Item.cpp

pub struct Item {
  item_id : Int
  expiration : Int64
  owner : String
  flags : Int
}

pub fn Item::new(
  item_id : Int,
  expiration : Int64,
  owner : String,
  flags : Int
) -> Item {
  { item_id, expiration, owner, flags }
}
