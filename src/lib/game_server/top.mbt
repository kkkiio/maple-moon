///|
/// send client message to the server
#callsite(autofill(loc))
pub fn[T : ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(log_level, { "message": json }, "send", loc~)
  default_server.client_message_queue.push((type_code, json))
}

///|
pub fn add_server_message_handler(
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  default_server.server_message_handlers_map
  .get_or_init(type_code, fn() { Array::new() })
  .push((name, handler))
}

///|
pub fn server_system(_delta : Double) -> Unit {
  while default_server.server_message_queue.pop() is Some((type_code, json)) {
    guard default_server.server_message_handlers_map.get(type_code)
      is Some(handlers) else {
      continue
    }
    for handler in handlers {
      (handler.1)(json) catch {
        err =>
          @log.error(
            { "error": err.to_string(), "name": handler.0 },
            "Error handling server message",
          )
      }
    }
  }
  while default_server.client_message_queue.pop() is Some((type_code, json)) {
    guard default_server.client_message_handler_map.get(type_code)
      is Some(handler) else {
      abort(
        "Missing client message handler for type code: \{type_code}, json: \{json}",
      )
    }
    handler(json) catch {
      err => abort("Error handling client message: \{err.to_string()}")
    }
  }
}

///|
let default_server : LocalServer = LocalServer::new()
