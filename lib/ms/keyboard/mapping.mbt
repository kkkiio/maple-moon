///|
pub struct Mapping {
  t : KeyType
  action : Int // opaque
} derive(Eq,Show)

///|
pub fn Mapping::new(in_type : KeyType, in_action : Int) -> Mapping {
  { t: in_type, action: in_action }
}
