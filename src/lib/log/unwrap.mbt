///|
#callsite(autofill(loc))
pub fn[T] unwrap_err(result : Result[T, Error], loc~ : SourceLoc) -> T {
  match result {
    Ok(value) => value
    Err(err) => {
      error("abort", data={ "err": err }, loc~)
      panic()
    }
  }
}
