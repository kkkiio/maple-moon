///|
#callsite(autofill(loc))
pub fn log(
  level : Level,
  msg : String,
  data? : Map[String, &Show],
  loc~ : SourceLoc,
) -> Unit {
  match level {
    Level::TRACE => () // do nothing
    Level::DEBUG => log_debug(to_logstr(msg, data?, loc))
    Level::INFO => log_info(to_logstr(msg, data?, loc))
    Level::WARN => log_warn(to_logstr(msg, data?, loc))
    Level::ERROR => log_error(to_logstr(msg, data?, loc))
  }
}

///|
#callsite(autofill(loc))
pub fn debug(
  msg : String,
  data? : Map[String, &Show],
  loc~ : SourceLoc,
) -> Unit {
  log_debug(to_logstr(msg, data?, loc))
}

///|
#callsite(autofill(loc))
pub fn info(msg : String, data? : Map[String, &Show], loc~ : SourceLoc) -> Unit {
  log_info(to_logstr(msg, data?, loc))
}

///|
#callsite(autofill(loc))
pub fn warn(msg : String, data? : Map[String, &Show], loc~ : SourceLoc) -> Unit {
  log_warn(to_logstr(msg, data?, loc))
}

///|
#callsite(autofill(loc))
pub fn error(
  msg : String,
  data? : Map[String, &Show],
  loc~ : SourceLoc,
) -> Unit {
  log_error(to_logstr(msg, data?, loc))
}

///|
/// Always panic after logging.
#callsite(autofill(loc))
pub fn[T] fatal(
  msg : String,
  data? : Map[String, &Show],
  loc~ : SourceLoc,
) -> T {
  log_error(to_logstr(msg, data?, loc))
  panic()
}

///|
fn to_logstr(
  msg : String,
  data? : Map[String, &Show],
  loc : SourceLoc,
) -> String {
  let buf = StringBuilder::new(
    size_hint=(msg.length() + data.map_or(0, fn(m) { m.length() }) * 12) * 2,
  )
  buf.write_string("loc=")
  buf.write_string(loc.to_string())
  buf.write_string(" msg=")
  Show::output(msg, buf)
  if data is Some(data) {
    for k, v in data {
      buf.write_string(" ")
      buf.write_string(k)
      buf.write_string("=")
      Show::output(v, buf)
    }
  }
  buf.to_string()
}

///|
pub(all) enum Level {
  TRACE
  DEBUG
  INFO
  WARN
  ERROR
}
