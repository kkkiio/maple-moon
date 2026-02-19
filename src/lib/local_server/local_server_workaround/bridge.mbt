///|
using @maple_protocol {trait ClientMessage}

///|
let default_server : @local_server.LocalServer = @local_server.LocalServer::new()

///|
pub fn init_server() -> Unit {
  @io_service.execute_background(async fn() {
    @local_server.init_server(default_server)
  })
}

///|
/// send client message to the server
#callsite(autofill(loc))
pub fn[T : ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  default_server.send_client_message(message, log_level~, loc~)
}

///|
pub fn add_server_message_handler(
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  default_server.add_server_message_handler(name, type_code, handler)
}

///|
pub fn server_system(_delta : Double) -> Unit {
  @local_server.server_system(default_server)
}
