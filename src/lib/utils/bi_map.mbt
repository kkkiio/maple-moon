///|
struct BiMap[K, V] {
  forward : Map[K, V]
  backward : Map[V, K]
}

///|
pub fn[K, V] BiMap::new() -> BiMap[K, V] {
  { forward: Map::new(), backward: Map::new() }
}

///|
pub fn[K : Eq + Hash, V] BiMap::get_forward(self : BiMap[K, V], k : K) -> V? {
  self.forward.get(k)
}

///|
pub fn[K, V : Eq + Hash] BiMap::get_backward(self : BiMap[K, V], v : V) -> K? {
  self.backward.get(v)
}

///|
pub fn[K : Eq + Hash, V : Eq + Hash] BiMap::set(
  self : BiMap[K, V],
  k : K,
  v : V
) -> Unit {
  self.forward.set(k, v)
  self.backward.set(v, k)
}

///|
pub fn[K : Eq + Hash, V : Eq + Hash] BiMap::from_array(
  array : Array[(K, V)]
) -> BiMap[K, V] {
  {
    forward: Map::from_iter(array.iter()),
    backward: Map::from_iter(array.iter().map(fn(e) { (e.1, e.0) })),
  }
}
