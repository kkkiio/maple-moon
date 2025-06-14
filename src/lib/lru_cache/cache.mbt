///|
struct Cache[K, V] {
  map : Map[K, V]
  capacity : Int
}

///|
pub fn[K, V] Cache::new(capacity : Int) -> Cache[K, V] {
  if capacity <= 0 {
    abort("capacity must be positive")
  }
  { map: Map::new(), capacity }
}

///|
pub fn[K : Hash + Eq, V] get(self : Cache[K, V], key : K) -> V? {
  match self.map.get(key) {
    Some(value) => {
      // built-in map will mantain the order of insertion, so we just need to remove the key and re-insert it
      self.map.remove(key)
      self.map.set(key, value)
      Some(value)
    }
    None => None
  }
}

///|
pub fn[K : Hash + Eq, V] set(self : Cache[K, V], key : K, value : V) -> Unit {
  self.map.remove(key) // ensure we re-insert the key
  if self.map.size() >= self.capacity {
    let first_key = self.map.iter().find_first(fn(_it) { true }).unwrap().0
    self.map.remove(first_key)
  }
  self.map.set(key, value)
}

///|
pub fn[K, V] clear(self : Cache[K, V]) -> Unit {
  self.map.clear()
}
