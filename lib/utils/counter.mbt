///|
pub(all) type Counter[K, V] Map[K, V]

///|
pub fn Counter::new[K, V]() -> Counter[K, V] {
  Map::new()
}

///|
pub fn op_get[K : Hash + Eq, V : Default](self : Counter[K, V], key : K) -> V {
  self._.get_or_init(key, fn() { V::default() })
}

///|
pub fn op_set[K : Hash + Eq, V](
  self : Counter[K, V],
  key : K,
  value : V
) -> Unit {
  self._.set(key, value)
}
