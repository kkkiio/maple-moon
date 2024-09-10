pub type Counter[K] Map[K, Int]

pub fn Counter::new[K]() -> Counter[K] {
  Map::new()
}

pub fn op_get[K : Hash + Eq](self : Counter[K], key : K) -> Int {
  self._.get_or_init(key, fn() { 0 })
}

pub fn op_set[K : Hash + Eq](self : Counter[K], key : K, value : Int) -> Unit {
  self._.set(key, value)
}
