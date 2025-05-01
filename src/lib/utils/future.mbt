///| A poll-based future. Holds a value that will be available in the future.
///
/// Once the future is resolved, the value is cached and the function is not called again.
struct Future[T] {
  poll_fn : () -> T?
  mut resolved : T?
}

///| Poll the future.
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

///| Create a new future from a poll function.
pub fn Future::new[T](poll_fn : () -> T?) -> Future[T] {
  { poll_fn, resolved: None }
}

///| Create a future from a resolved value.
pub fn Future::from_value[T](v : T) -> Future[T] {
  { poll_fn: fn() { Some(v) }, resolved: Some(v) }
}

///| Create a future that never resolves.
/// Useful for representing a uninitialized value.
pub fn Future::never[T]() -> Future[T] {
  Future::new(fn() { None })
}

///|
pub fn map[T, U](self : Future[T], f : (T) -> U) -> Future[U] {
  Future::new(fn() {
    match self.poll() {
      Some(t) => Some(f(t))
      None => None
    }
  })
}

///|
pub fn bind[T, U](self : Future[T], f : (T) -> Future[U]) -> Future[U] {
  self.map(f).flatten()
}

///|
pub fn flatten[T](self : Future[Future[T]]) -> Future[T] {
  Future::new(fn() {
    match self.poll() {
      Some(f) => f.poll()
      None => None
    }
  })
}

///|
pub fn map_exn[T, U, E : Error](
  self : Future[T],
  f : (T) -> U!E
) -> Future[Result[U, E]] {
  self.map(fn(t) {
    try {
      Ok(f!(t))
    } catch {
      e => Err(e)
    }
  })
}

///|
pub fn tap[T](self : Future[T], f : (T) -> Unit) -> Future[T] {
  self.map(fn(t) {
    f(t)
    t
  })
}

///|
pub fn combine[T, U](self : Future[T], other : Future[U]) -> Future[(T, U)] {
  self.map(fn(t) { other.map(fn(u) { (t, u) }) }).flatten()
}

///|
pub fn Future::all_of[T](futures : Array[Future[T]]) -> Future[Array[T]] {
  let resolved = Array::new()
  let mut i = 0
  Future::new(fn() {
    while i < futures.length() {
      match futures[i].poll() {
        Some(t) => resolved.push(t)
        None => return None // maybe poll other futures to do more work?
      }
      i += 1
    }
    Some(resolved)
  })
}

///| Advance and remove completed futures.
pub fn advance_futures(futures : Array[Future[Unit]]) -> Unit {
  futures.retain(fn(f) {
    match f.poll() {
      Some(_) => false
      None => true
    }
  })
}

///| Return a future that will be resolved when the `poll` is called.
pub fn Future::lazy[T](f : () -> T) -> Future[T] {
  Future::new(fn() { f() |> Some })
}
