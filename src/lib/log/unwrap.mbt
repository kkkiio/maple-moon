///|
pub fn[T] unwrap_err(result : Result[T, Error], loc~ : SourceLoc = _) -> T {
  match result {
    Ok(value) => value
    Err(err) => {
      error({ "err": err }, "abort", loc~)
      panic()
    }
  }
}
