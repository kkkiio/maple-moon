pub fn log(
  level : Level,
  context : Map[String, Show],
  msg : String,
  ~loc : SourceLoc = _
) -> Unit {
  match level {
    Level::TRACE => () // do nothing
    Level::DEBUG => log_debug(to_logstr(context, msg, loc))
    Level::INFO => log_info(to_logstr(context, msg, loc))
    Level::WARN => log_warn(to_logstr(context, msg, loc))
    Level::ERROR => log_error(to_logstr(context, msg, loc))
  }
}

pub fn debug(
  context : Map[String, Show],
  msg : String,
  ~loc : SourceLoc = _
) -> Unit {
  log_debug(to_logstr(context, msg, loc))
}

pub fn info(
  context : Map[String, Show],
  msg : String,
  ~loc : SourceLoc = _
) -> Unit {
  log_info(to_logstr(context, msg, loc))
}

pub fn warn(
  context : Map[String, Show],
  msg : String,
  ~loc : SourceLoc = _
) -> Unit {
  log_warn(to_logstr(context, msg, loc))
}

pub fn error(
  context : Map[String, Show],
  msg : String,
  ~loc : SourceLoc = _
) -> Unit {
  log_error(to_logstr(context, msg, loc))
}

fn to_logstr(
  context : Map[String, Show],
  msg : String,
  loc : SourceLoc
) -> String {
  let buf = StringBuilder::new(
    size_hint=(msg.length() + context.size() * 12) * 2,
  )
  buf.write_string("loc=")
  buf.write_string(loc.to_string())
  buf.write_string(" ")
  // TODO: escape if needed
  for k, v in context {
    buf.write_string(k)
    buf.write_string("=")
    Show::output(v, buf)
    buf.write_string(" ")
  }
  buf.write_string("msg=")
  buf.write_string(msg)
  buf.to_string()
}

pub enum Level {
  TRACE
  DEBUG
  INFO
  WARN
  ERROR
}
