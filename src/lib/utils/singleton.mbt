struct Singleton[T] {
  mut instance : T?
}

pub fn Singleton::new[T]() -> Singleton[T] {
  { instance: None }
}

pub fn Singleton::set[T](self : Singleton[T], value : T) -> Unit {
  self.instance = Some(value)
}

pub fn must_get[T](self : Singleton[T]) -> T {
  self.instance.unwrap()
}
