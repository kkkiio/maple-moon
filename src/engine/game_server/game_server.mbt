///|
/// Runtime contract used by the client-facing game-server facade.
///
/// Implementations receive already encoded client messages so the public
/// generic `send` function remains shared by local, remote, and test servers.
///
/// # Example
/// ```moonbit nocheck
/// let server : &GameServer = make_server()
/// install(server)
/// init_server()
/// ```
pub(open) trait GameServer {
  /// Initialize server-side services and message routes.
  fn initialize(Self) -> Unit

  /// Accept one encoded client message.
  fn send_json(Self, Int, Json, @log.Level, SourceLoc) -> Unit

  /// Register a handler for one server-message type.
  fn register_handler(Self, String, Int, (Json) -> Unit raise) -> Unit

  /// Advance server work by one game update.
  fn tick(Self, Double) -> Unit
}

///|
let installed_server : Ref[&GameServer?] = Ref(None)

///|
/// Install the server used by the client-facing facade.
///
/// Installing another server replaces the current instance, allowing each
/// application or black-box test to provide an isolated implementation.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.install(local_server)
/// ```
pub fn install(server : &GameServer) -> Unit {
  installed_server.val = Some(server)
}

///|
/// Send a typed client message through the installed game server.
///
/// The facade encodes the message once and preserves the caller location for
/// implementation-side logging.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.send(message)
/// ```
#callsite(autofill(loc))
pub fn[T : @server_proto.ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  guard installed_server.val is Some(server) else {
    abort("game server is not installed")
  }
  GameServer::send_json(
    server,
    T::type_code(),
    ToJson::to_json(message),
    log_level,
    loc,
  )
}

///|
/// Register a server-message handler on the installed game server.
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
  guard installed_server.val is Some(server) else {
    abort("game server is not installed")
  }
  GameServer::register_handler(server, name, type_code, handler)
}

///|
/// Run one update on the installed game server.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.server_system(1.0 / 60.0)
/// ```
pub fn server_system(delta : Double) -> Unit {
  guard installed_server.val is Some(server) else {
    abort("game server is not installed")
  }
  GameServer::tick(server, delta)
}

///|
/// Initialize the installed game server.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.init_server()
/// ```
pub fn init_server() -> Unit {
  guard installed_server.val is Some(server) else {
    abort("game server is not installed")
  }
  GameServer::initialize(server)
}
