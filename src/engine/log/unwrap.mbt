///|
#callsite(autofill(loc))
pub fn[T] unwrap_rst(result : Result[T, Error], loc~ : SourceLoc) -> T {
  match result {
    Ok(value) => value
    Err(err) => {
      error("unwrap result fail", data={ "err": err }, loc~)
      panic()
    }
  }
}

///|
#callsite(autofill(loc))
pub fn[T] unwrap_opt(opt : T?, loc~ : SourceLoc) -> T {
  match opt {
    Some(value) => value
    None => {
      error("unwrap option fail", loc~)
      panic()
    }
  }
}
