///|
/// Send a client message to game server.
///
/// The default virtual-package implementation is a no-op fallback.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.send(message)
/// ```
#warnings("-unused_trait_bound")
#callsite(autofill(loc))
pub fn[T : @server_proto.ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  ignore(message)
  ignore(log_level)
  ignore(loc)
}

///|
/// Register a server-message handler.
///
/// The default virtual-package implementation is a no-op fallback.
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
  ignore(name)
  ignore(type_code)
  ignore(handler)
}

///|
/// Run one server tick.
///
/// The default virtual-package implementation is a no-op fallback.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.server_system(1.0 / 60.0)
/// ```
pub fn server_system(delta : Double) -> Unit {
  ignore(delta)
}

///|
/// Initialize server-side services.
///
/// The default virtual-package implementation is a no-op fallback.
///
/// # Example
/// ```moonbit nocheck
/// @game_server.init_server()
/// ```
pub fn init_server() -> Unit {

}
