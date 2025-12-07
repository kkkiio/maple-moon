///|
/// Submits an asynchronous task for execution in the background and returns a `Future` to track its result.
/// The task is an `async` block that can return a value of type `T` or throw an `Error`.
/// The returned `Future` will eventually resolve to a `Result[T, Error]`.
pub fn[T] submit_background_task(
  task : async () -> T,
) -> Future[Result[T, Error]] {
  let mut res : Result[T, Error]? = None
  spawn_background(fn() {
    try {
      let value = task()
      res = Some(Ok(value))
    } catch {
      e => res = Some(Err(e))
    }
  })
  Future::new(fn() { res })
}

///|
/// Executes a "fire-and-forget" asynchronous task.
/// This is useful for tasks that are executed for their side effects, where the return value is not needed.
pub fn execute_background(
  f : async () -> Unit,
  /// An optional callback function to handle any `Error` thrown by the task.
  /// If not provided, the default behavior is to abort the program.
  on_error? : (Error) -> Unit = fn(err) { abort(err.to_string()) },
) -> Unit {
  spawn_background(fn() { f() catch { e => on_error(e) } })
}

///|
pub async fn[T] wait_future(future : Future[T]) -> T {
  if future.poll() is Some(res) {
    return res
  }
  @js.suspend(fn(resume_ok, _resume_err) {
    poll_tasks.push(future.map(fn(res) { resume_ok(res) }))
  })
}

///|
/// A queue of tasks to be polled.
let poll_tasks : Array[Future[Unit]] = Array::new()

///|
/// Run the submitted tasks.
pub fn io_system(_delta : Double) -> Unit {
  poll_tasks.retain(fn(future) {
    match future.poll() {
      Some(_) => false
      None => true
    }
  })
}

///|
using @utils {type Future}
