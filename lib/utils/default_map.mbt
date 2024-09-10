pub struct DefaultMap[K, V] {
  map : Map[K, V]
  default_fn : () -> V
}

pub fn DefaultMap::new[K, V](default_fn : () -> V) -> DefaultMap[K, V] {
  { map: Map::new(), default_fn }
}

pub fn op_get[K : Eq + Hash, V](self : DefaultMap[K, V], key : K) -> V {
  self.map.get_or_init(key, self.default_fn)
}
