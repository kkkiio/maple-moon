///|
struct Service {
  io_tasks : Array[@utils.Future[Unit]]
}

///|
pub fn Service::new() -> Service {
  { io_tasks: Array::new() }
}

///|
pub fn add(self : Service, future : @utils.Future[Unit]) -> Unit {
  self.io_tasks.push(future)
}

///|
pub fn on_complete[T](
  self : Service,
  future : @utils.Future[T],
  cb : (T) -> Unit
) -> Unit {
  self.io_tasks.push(future.map(fn(it) { cb(it) }))
}

///|
pub fn run(self : Service) -> Unit {
  self.io_tasks.retain(fn(f) { f.poll().is_empty() })
}
