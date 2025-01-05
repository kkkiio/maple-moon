pub(all) struct Mapping {
  t : KeyType
  action : Int
} derive(Eq, Compare)

pub fn Mapping::new(in_type : KeyType, in_action : Int) -> Mapping {
  { t: in_type, action: in_action }
}
