///|
/// Submits a task and returns a `Future` to track its result.
/// The task runs immediately on the game thread.
/// The returned `Future` will eventually resolve to a `Result[T, Error]`.
pub fn[T] submit_background_task(
  task : () -> T raise,
) -> Future[Result[T, Error]] {
  let res : Result[T, Error]? = Some(try? task())
  Future::new(fn() { res })
}

///|
/// Executes a "fire-and-forget" task.
/// This is useful for tasks that are executed for their side effects, where the return value is not needed.
pub fn execute_background(
  f : () -> Unit raise,
  /// An optional callback function to handle any `Error` thrown by the task.
  /// If not provided, the default behavior is to abort the program.
  on_error? : (Error) -> Unit = fn(err) { abort(err.to_string()) },
) -> Unit {
  spawn_background(fn() { f() catch { err => on_error(err) } })
}

///|
/// A queue of tasks to be polled.
let poll_tasks : Array[Future[Unit]] = Array::new()

///|
/// Run the submitted tasks.
pub fn io_system(_world : @ecs.World) -> Unit {
  poll_tasks.retain(fn(future) {
    match future.poll() {
      Some(_) => false
      None => true
    }
  })
}

///|
using @utils {type Future}

///|
fn spawn_background(f : () -> Unit) -> Unit {
  f()
}
