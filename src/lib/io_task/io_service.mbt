///|
struct IOService {} derive(Default)

///|
pub fn IOService::new() -> IOService {
  Default::default()
}

///|
pub fn[T] IOService::submit(
  _ : IOService,
  task : async () -> T!Error
) -> @utils.Future[Result[T, Error]] {
  let mut res : Result[T, Error]? = None
  spawn_background(async fn() {
    try {
      let value = task!()
      res = Some(Ok(value))
    } catch {
      e => res = Some(Err(e))
    }
  })
  @utils.Future::new(fn() { res })
}
