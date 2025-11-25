///|
/// A service for executing IO-bound tasks in the background.
struct IOService {} derive(Default)

///|
/// Creates a new instance of `IOService`.
pub fn IOService::new() -> IOService {
  Default::default()
}

///|
/// Submits an asynchronous task for execution and returns a `Future` to track its result.
/// The task is an `async` block that can return a value of type `T` or throw an `Error`.
/// The returned `Future` will eventually resolve to a `Result[T, Error]`.
pub fn[T] IOService::submit(
  _ : IOService,
  task : async () -> T,
) -> @utils.Future[Result[T, Error]] {
  let mut res : Result[T, Error]? = None
  spawn_background(fn() {
    try {
      let value = task()
      res = Some(Ok(value))
    } catch {
      e => res = Some(Err(e))
    }
  })
  @utils.Future::new(fn() { res })
}

///|
/// Executes a "fire-and-forget" asynchronous task.
/// This is useful for tasks that are executed for their side effects, where the return value is not needed.
pub fn IOService::execute(
  _ : IOService,
  f : async () -> Unit,
  /// An optional callback function to handle any `Error` thrown by the task.
  /// If not provided, the default behavior is to abort the program.
  on_error? : (Error) -> Unit = fn(err) { abort(err.to_string()) },
) -> Unit {
  spawn_background(fn() { f() catch { e => on_error(e) } })
}

///|
pub async fn[T] IOService::wait(
  self : IOService,
  future : @utils.Future[T],
) -> T {
  if future.poll() is Some(res) {
    return res
  }
  suspend(fn(resume_ok, _resume_err) {
    spawn_background_ffi(fn() { resume_ok(()) })
  })
  return self.wait(future)
}

///|
/// `suspend` will suspend the execution of the current coroutine.
/// The suspension will be handled by a callback passed to `suspend`
async fn[T, E : Error] suspend(
  // `f` is a callback for handling suspension
  f : (
    // the first parameter of `f` is used to resume the execution of the coroutine normally
    (T) -> Unit,
    // the second parameter of `f` is used to cancel the execution of the current coroutine
    // by throwing an error at suspension point
    (E) -> Unit,
  ) -> Unit,
) -> T raise E = "%async.suspend"
