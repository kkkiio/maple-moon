///|
using @server_proto {trait ClientMessage}

///|
priv struct BridgeState {
  mut server : @local_server.LocalServer?
}

///|
let state : BridgeState = { server: None }

///|
#cfg(target="js")
fn new_runtime_db() -> &@local_server.DB {
  @local_server.BrowserDB()
}

///|
#cfg(not(target="js"))
fn new_runtime_db() -> &@local_server.DB {
  @local_server.FileDB()
}

///|
/// Initialize the in-process local server for the current target.
///
/// JS builds use browser-local storage and native builds use file-backed
/// storage.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.init_server()
/// ```
pub fn init_server() -> Unit {
  let server = @local_server.LocalServer(
    db=new_runtime_db(),
    drop_rng=@random.Rand::chacha8(seed=@local_server.default_rand_seed.val),
  )
  state.server = Some(server)
  @local_server.init_server(server)
}

///|
/// Send a client message to the in-process local server.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.send(message)
/// ```
#callsite(autofill(loc))
pub fn[T : ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  guard state.server is Some(server) else {
    abort("local server is not initialized")
  }
  server.send_client_message(message, log_level~, loc~)
}

///|
/// Register a server-message handler on the in-process local server.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.add_server_message_handler("set_field", type_code, handler)
/// ```
pub fn add_server_message_handler(
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  guard state.server is Some(server) else {
    abort("local server is not initialized")
  }
  server.add_server_message_handler(name, type_code, handler)
}

///|
/// Run one in-process local server tick.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.server_system(1.0 / 60.0)
/// ```
pub fn server_system(_delta : Double) -> Unit {
  guard state.server is Some(server) else { return }
  @local_server.server_system(server)
}
