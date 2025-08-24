///|
struct Singleton[T] {
  mut instance : T?
}

///|
pub fn[T] Singleton::new() -> Singleton[T] {
  { instance: None }
}

///|
pub fn[T] Singleton::set(self : Singleton[T], value : T) -> Unit {
  self.instance = Some(value)
}

///|
pub fn[T] must_get(self : Singleton[T]) -> T {
  self.instance.unwrap()
}
