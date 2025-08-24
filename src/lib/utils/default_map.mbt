///|
pub(all) struct DefaultMap[K, V] {
  map : Map[K, V]
  default_fn : () -> V
}

///|
pub fn[K, V] DefaultMap::new(default_fn : () -> V) -> DefaultMap[K, V] {
  { map: Map::new(), default_fn }
}

///|
pub fn[K : Eq + Hash, V] DefaultMap::op_get(
  self : DefaultMap[K, V],
  key : K
) -> V {
  self.map.get_or_init(key, self.default_fn)
}
