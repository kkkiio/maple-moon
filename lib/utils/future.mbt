///| A future is a value that will be available in the future.
///
/// Once the future is resolved, the value is cached and the function is not called again.
struct Future[T] {
  poll_fn : () -> T?
  mut resolved : T?
}

pub fn Future::new[T](poll_fn : () -> T?) -> Future[T] {
  { poll_fn, resolved: None }
}

pub fn Future::from_value[T](v : T) -> Future[T] {
  { poll_fn: fn() { Some(v) }, resolved: Some(v) }
}

pub fn Future::never[T]() -> Future[T] {
  Future::new(fn() { None })
}

pub fn poll[T](self : Future[T]) -> T? {
  match self.resolved {
    Some(_) => self.resolved
    None => {
      let v = (self.poll_fn)()
      self.resolved = v
      v
    }
  }
}

pub fn map[T, U](self : Future[T], f : (T) -> U) -> Future[U] {
  Future::new(
    fn() {
      match self.poll() {
        Some(t) => Some(f(t))
        None => None
      }
    },
  )
}

pub fn bind[T, U](self : Future[T], f : (T) -> Future[U]) -> Future[U] {
  self.map(f).flatten()
}

pub fn flatten[T](self : Future[Future[T]]) -> Future[T] {
  Future::new(
    fn() {
      match self.poll() {
        Some(f) => f.poll()
        None => None
      }
    },
  )
}

pub fn map_exn[T, U, E : Error](
  self : Future[T],
  f : (T) -> U!E
) -> Future[Result[U, E]] {
  self.map(
    fn(t) {
      try {
        Ok(f!(t))
      } catch {
        e => Err(e)
      }
    },
  )
}

pub fn tap[T](self : Future[T], f : (T) -> Unit) -> Future[T] {
  self.map(
    fn(t) {
      f(t)
      t
    },
  )
}

pub fn combine[T, U](self : Future[T], other : Future[U]) -> Future[(T, U)] {
  self.map(fn(t) { other.map(fn(u) { (t, u) }) }).flatten()
}
