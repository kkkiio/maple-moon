///|
struct PollService {
  io_tasks : Array[@utils.Future[Unit]]
}

///|
pub fn PollService::new() -> PollService {
  { io_tasks: Array::new() }
}

///|
pub fn PollService::add(
  self : PollService,
  future : @utils.Future[Unit]
) -> Unit {
  self.io_tasks.push(future)
}

///|
pub fn[T] on_complete(
  self : PollService,
  future : @utils.Future[T],
  cb : (T) -> Unit
) -> Unit {
  self.io_tasks.push(future.map(fn(it) { cb(it) }))
}

///|
pub fn run(self : PollService) -> Unit {
  self.io_tasks.retain(fn(f) { f.poll().is_empty() })
}
