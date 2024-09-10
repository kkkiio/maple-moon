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
