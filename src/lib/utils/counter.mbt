///|
pub(all) struct Counter[K, V](Map[K, V])

///|
pub fn[K, V] Counter::new() -> Counter[K, V] {
  Map::new()
}

///|
pub fn[K : Hash + Eq, V : Default] Counter::op_get(
  self : Counter[K, V],
  key : K,
) -> V {
  self.0.get_or_init(key, fn() { V::default() })
}

///|
pub fn[K : Hash + Eq, V] Counter::op_set(
  self : Counter[K, V],
  key : K,
  value : V,
) -> Unit {
  self.0.set(key, value)
}
