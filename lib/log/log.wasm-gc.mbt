
fn log_debug(msg : String) -> Unit = "console" "debug"

extern "js" fn log_info(msg : String) -> Unit =
  #| (m) => console.info(m)

extern "js" fn log_warn(msg : String) -> Unit =
  #| (m) => console.warn(m)

extern "js" fn log_error(msg : String) -> Unit =
  #| (m) => console.error(m)
