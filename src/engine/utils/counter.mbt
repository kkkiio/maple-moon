///|
pub(all) struct Counter[K, V] {
  values : Map[K, V]
}

///|
pub fn[K : Eq + Hash, V] Counter::Counter() -> Counter[K, V] {
  { values: Map([]) }
}

///|
pub fn[K : Hash + Eq, V : Default] Counter::op_get(
  self : Counter[K, V],
  key : K,
) -> V {
  self.values.get_or_init(key, fn() { V::default() })
}

///|
pub fn[K : Hash + Eq, V] Counter::op_set(
  self : Counter[K, V],
  key : K,
  value : V,
) -> Unit {
  self.values.set(key, value)
}
