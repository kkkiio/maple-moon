struct Cache[K, V] {
  map : Map[K, V]
  capacity : Int
}

pub fn Cache::new[K, V](capacity : Int) -> Cache[K, V] {
  if capacity <= 0 {
    abort("capacity must be positive")
  }
  { map: Map::new(), capacity }
}

pub fn get[K : Hash + Eq, V](self : Cache[K, V], key : K) -> V? {
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

pub fn set[K : Hash + Eq, V](self : Cache[K, V], key : K, value : V) -> Unit {
  self.map.remove(key) // ensure we re-insert the key
  if self.map.size() >= self.capacity {
    let first_key = self.map.iter().find_first(fn(_it) { true }).unwrap().0
    self.map.remove(first_key)
  }
  self.map.set(key, value)
}

pub fn clear[K, V](self : Cache[K, V]) -> Unit {
  self.map.clear()
}
