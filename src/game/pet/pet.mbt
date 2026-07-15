///|
pub(all) struct Pet {
  pet_name : String
}

///|
pub fn Pet::Pet(petname : String) -> Pet {
  { pet_name: petname }
}
