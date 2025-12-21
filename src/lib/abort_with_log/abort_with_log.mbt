///|
pub fn[T] abort(message : String) -> T {
  @log.error({}, message)
  panic()
}
