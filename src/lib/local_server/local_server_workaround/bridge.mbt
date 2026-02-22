///|
using @maple_protocol {trait ClientMessage}

///|
priv struct BridgeState {
  mut server : @local_server.LocalServer?
}

///|
let state : BridgeState = { server: None }

///|
pub fn init_server() -> Unit {
  let server = @local_server.LocalServer::new(
    db=@local_server.BrowserDB::new(),
    drop_rng=@random.Rand::chacha8(seed=@local_server.default_rand_seed.val),
  )
  state.server = Some(server)
  @local_server.init_server(server)
}

///|
/// send client message to the server
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
pub fn server_system(_delta : Double) -> Unit {
  guard state.server is Some(server) else { return }
  @local_server.server_system(server)
}
