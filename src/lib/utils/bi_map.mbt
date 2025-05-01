///|
struct BiMap[K, V] {
  forward : Map[K, V]
  backward : Map[V, K]
}

///|
pub fn BiMap::new[K, V]() -> BiMap[K, V] {
  { forward: Map::new(), backward: Map::new() }
}

///|
pub fn BiMap::get_forward[K : Eq + Hash, V](self : BiMap[K, V], k : K) -> V? {
  self.forward.get(k)
}

///|
pub fn BiMap::get_backward[K, V : Eq + Hash](self : BiMap[K, V], v : V) -> K? {
  self.backward.get(v)
}

///|
pub fn BiMap::set[K : Eq + Hash, V : Eq + Hash](
  self : BiMap[K, V],
  k : K,
  v : V
) -> Unit {
  self.forward.set(k, v)
  self.backward.set(v, k)
}

///|
pub fn BiMap::from_array[K : Eq + Hash, V : Eq + Hash](
  array : Array[(K, V)]
) -> BiMap[K, V] {
  {
    forward: Map::from_iter(array.iter()),
    backward: Map::from_iter(array.iter().map(fn(e) { (e.1, e.0) })),
  }
}
