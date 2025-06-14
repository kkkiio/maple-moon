///|
pub(all) type Counter[K, V] Map[K, V]

///|
pub fn[K, V] Counter::new() -> Counter[K, V] {
  Map::new()
}

///|
pub fn[K : Hash + Eq, V : Default] Counter::op_get(
  self : Counter[K, V],
  key : K
) -> V {
  self._.get_or_init(key, fn() { V::default() })
}

///|
pub fn[K : Hash + Eq, V] op_set(
  self : Counter[K, V],
  key : K,
  value : V
) -> Unit {
  self._.set(key, value)
}
