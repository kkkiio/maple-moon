pub struct Pet {
  pet_name : String
}

pub fn Pet::new(petname : String) -> Pet {
  { pet_name: petname }
}
