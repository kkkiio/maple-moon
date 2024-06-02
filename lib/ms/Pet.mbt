// app/src/main/cpp/src/Character/Inventory/Pet.h
// app/src/main/cpp/src/Character/Inventory/Pet.cpp

pub struct Pet {
  pet_name : String
}

pub fn Pet::new(
  item_id : Int,
  expiration : Int64,
  petname : String,
  level : Int,
  closeness : Int,
  fullness : Int
) -> Pet {
  { pet_name: petname }
}
