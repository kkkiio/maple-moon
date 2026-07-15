///|
#borrow(executable, log_path, cdp_port, game_url)
extern "C" fn spawn_detached_ffi(
  executable : Bytes,
  log_path : Bytes,
  cdp_port : Bytes,
  game_url : Bytes,
) -> Int = "maple_moon_spawn_detached"

///|
fn spawn_detached_mapled(
  executable : String,
  log_path : String,
  cdp_port : String,
  game_url : String,
) -> Unit raise {
  let error = spawn_detached_ffi(
    @utf8.encode(executable + "\u0000"),
    @utf8.encode(log_path + "\u0000"),
    @utf8.encode(cdp_port + "\u0000"),
    @utf8.encode(game_url + "\u0000"),
  )
  guard error == 0 else {
    fail("failed to start detached mapled process: error code \{error}")
  }
}
