///|
/// Stateful `GameServer` test double with explicit message observation APIs.
///
/// Each instance owns its sent messages and registered handlers, so black-box
/// tests can install isolated servers without sharing test state.
///
/// # Example
/// ```moonbit nocheck
/// let server = MockServer()
/// @game_server.install(server)
/// @game_server.init_server()
/// ```
pub struct MockServer {
  sent_messages : Array[(Int, Json)]
  handlers : Map[Int, Array[(Json) -> Unit raise]]
  mut ticks : Int
}

///|
/// Create an empty mock game server.
///
/// # Example
/// ```moonbit nocheck
/// let server = MockServer()
/// inspect(server.sent_count(42), content="0")
/// ```
pub fn MockServer::MockServer() -> MockServer {
  { sent_messages: [], handlers: Map([]), ticks: 0 }
}

///|
/// Emit a typed server message to every matching registered handler.
///
/// # Example
/// ```moonbit nocheck
/// server.emit(message)
/// ```
pub fn[T : @server_proto.ServerMessage] MockServer::emit(
  self : MockServer,
  message : T,
) -> Unit raise {
  let type_code = T::type_code()
  let payload = ToJson::to_json(message)
  for handler in self.handlers.get(type_code).unwrap_or([]) {
    handler(payload)
  }
}

///|
/// Return how many client messages with `type_code` were sent.
///
/// # Example
/// ```moonbit nocheck
/// inspect(server.sent_count(type_code), content="1")
/// ```
pub fn MockServer::sent_count(self : MockServer, type_code : Int) -> Int {
  let mut count = 0
  for message in self.sent_messages {
    if message.0 == type_code {
      count += 1
    }
  }
  count
}

///|
/// Return the latest sent client-message JSON for `type_code`.
///
/// Returns `None` when no matching message has been sent.
///
/// # Example
/// ```moonbit nocheck
/// let latest = server.latest_sent_json(type_code)
/// ```
pub fn MockServer::latest_sent_json(
  self : MockServer,
  type_code : Int,
) -> Json? {
  let mut latest : Json? = None
  for message in self.sent_messages {
    if message.0 == type_code {
      latest = Some(message.1)
    }
  }
  latest
}

///|
/// Return how many server ticks this mock has received since initialization.
///
/// # Example
/// ```moonbit nocheck
/// inspect(server.tick_count(), content="0")
/// ```
pub fn MockServer::tick_count(self : MockServer) -> Int {
  self.ticks
}

///|
pub impl @game_server.GameServer for MockServer with fn initialize(self) {
  self.sent_messages.clear()
  self.handlers.clear()
  self.ticks = 0
}

///|
pub impl @game_server.GameServer for MockServer with fn send_json(
  self,
  type_code,
  payload,
  _log_level,
  _loc,
) {
  self.sent_messages.push((type_code, payload))
}

///|
pub impl @game_server.GameServer for MockServer with fn register_handler(
  self,
  _name,
  type_code,
  handler,
) {
  self.handlers.get_or_init(type_code, fn() { [] }).push(handler)
}

///|
pub impl @game_server.GameServer for MockServer with fn tick(self, _delta) {
  self.ticks += 1
}
