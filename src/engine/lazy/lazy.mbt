///|
/// Lazy initialization.
struct Lazy[T] {
  mut val : T?
  init_f : () -> T
}

///|
pub fn[T] Lazy::Lazy(init_f : () -> T) -> Lazy[T] {
  { val: None, init_f }
}

///|
/// get value or init.
pub fn[T] Lazy::get(self : Lazy[T]) -> T {
  if self.val is Some(val) {
    return val
  }
  let val = (self.init_f)()
  self.val = Some(val)
  val
}
