///|
let debug_log_ref : Ref[Bool] = Ref(false)

///|
fn init {
  let debug = @env.get_env_var("MAPLE_DEBUG") is Some("true" | "TRUE" | "1")
  debug_log_ref.val = debug
}

///|
fn log_debug(msg : String) -> Unit {
  println("DEBUG: " + msg)
}

///|
fn log_info(msg : String) -> Unit {
  println("INFO: " + msg)
}

///|
fn log_warn(msg : String) -> Unit {
  println("[warn] " + msg)
}

///|
fn log_error(msg : String) -> Unit {
  println("[error] " + msg)
}
