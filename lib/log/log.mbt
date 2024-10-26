pub fn log(level : Level, context : Map[String, Show], msg : String) -> Unit {
  match level {
    Level::TRACE => () // do nothing
    Level::DEBUG => log_debug(to_logstr(context, msg))
    Level::INFO => log_info(to_logstr(context, msg))
    Level::WARN => log_warn(to_logstr(context, msg))
    Level::ERROR => log_error(to_logstr(context, msg))
  }
}

pub fn debug(context : Map[String, Show], msg : String) -> Unit {
  log_debug(to_logstr(context, msg))
}

pub fn info(context : Map[String, Show], msg : String) -> Unit {
  log_info(to_logstr(context, msg))
}

pub fn warn(context : Map[String, Show], msg : String) -> Unit {
  log_warn(to_logstr(context, msg))
}

pub fn error(context : Map[String, Show], msg : String) -> Unit {
  log_error(to_logstr(context, msg))
}

fn to_logstr(context : Map[String, Show], msg : String) -> Js_string {
  let buf = StringBuilder::new(
    size_hint=(msg.length() + context.size() * 12) * 2,
  )
  context.each(fn(k, v) { buf.write_string("[\{k}=\{v}] ") })
  buf.write_string(msg)
  buf.to_string().to_js_string()
}

fn log_debug(msg : Js_string) -> Unit = "log" "debug"

fn log_info(msg : Js_string) -> Unit = "log" "info"

fn log_warn(msg : Js_string) -> Unit = "log" "warn"

fn log_error(msg : Js_string) -> Unit = "log" "error"

pub enum Level {
  TRACE
  DEBUG
  INFO
  WARN
  ERROR
}
