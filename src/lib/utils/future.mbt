///| A poll-based future. Holds a value that will be available in the future.
///
/// Once the future is resolved, the value is cached and the function is not called again.
struct Future[T] {
  poll_fn : () -> T?
  mut resolved : T?
}

///| Poll the future.
pub fn[T] poll(self : Future[T]) -> T? {
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
pub fn[T] Future::new(poll_fn : () -> T?) -> Future[T] {
  { poll_fn, resolved: None }
}

///| Create a future from a resolved value.
pub fn[T] Future::from_value(v : T) -> Future[T] {
  { poll_fn: fn() { Some(v) }, resolved: Some(v) }
}

///| Create a future that never resolves.
/// Useful for representing a uninitialized value.
pub fn[T] Future::never() -> Future[T] {
  Future::new(fn() { None })
}

///|
pub fn[T, U] map(self : Future[T], f : (T) -> U) -> Future[U] {
  Future::new(fn() {
    match self.poll() {
      Some(t) => Some(f(t))
      None => None
    }
  })
}

///|
pub fn[T, U] bind(self : Future[T], f : (T) -> Future[U]) -> Future[U] {
  self.map(f).flatten()
}

///|
pub fn[T] flatten(self : Future[Future[T]]) -> Future[T] {
  Future::new(fn() {
    match self.poll() {
      Some(f) => f.poll()
      None => None
    }
  })
}

///|
pub fn[T, U, E : Error] map_exn(
  self : Future[T],
  f : (T) -> U raise E
) -> Future[Result[U, E]] {
  self.map(fn(t) { Ok(f(t)) catch { e => Err(e) } })
}

///|
pub fn[T] tap(self : Future[T], f : (T) -> Unit) -> Future[T] {
  self.map(fn(t) {
    f(t)
    t
  })
}

///|
pub fn[T, U] combine(self : Future[T], other : Future[U]) -> Future[(T, U)] {
  self.map(fn(t) { other.map(fn(u) { (t, u) }) }).flatten()
}

///|
pub fn[T, U, V] combine3(
  self : Future[T],
  other1 : Future[U],
  other2 : Future[V]
) -> Future[(T, U, V)] {
  self.bind(fn(t) { other1.bind(fn(u) { other2.map(fn(v) { (t, u, v) }) }) })
}

///|
pub fn[T] Future::all_of(futures : Array[Future[T]]) -> Future[Array[T]] {
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
pub fn[T] Future::lazy(f : () -> T) -> Future[T] {
  Future::new(fn() { f() |> Some })
}
