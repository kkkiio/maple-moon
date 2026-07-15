///|
priv struct MockServerState {
  sent_messages : Array[(Int, Json)]
  handlers : Map[Int, Array[(Json) -> Unit raise]]
}

///|
let mock_server_state : MockServerState = {
  sent_messages: [],
  handlers: Map([]),
}

///|
pub fn reset_mock_server_state() -> Unit {
  mock_server_state.sent_messages.clear()
  mock_server_state.handlers.clear()
}

///|
pub fn emit_mock_server_state(type_code : Int, payload : Json) -> Unit raise {
  for handler in mock_server_state.handlers.get(type_code).unwrap_or([]) {
    handler(payload)
  }
}

///|
pub fn record_mock_server_sent_message(type_code : Int, payload : Json) -> Unit {
  mock_server_state.sent_messages.push((type_code, payload))
}

///|
pub fn add_mock_server_handler(
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  let handlers = mock_server_state.handlers.get(type_code).unwrap_or([])
  handlers.push(handler)
  mock_server_state.handlers[type_code] = handlers
}

///|
pub fn mock_server_sent_count_internal(type_code : Int) -> Int {
  let mut count = 0
  for message in mock_server_state.sent_messages {
    if message.0 == type_code {
      count += 1
    }
  }
  count
}

///|
pub fn mock_server_latest_sent_json_internal(type_code : Int) -> Json? {
  let mut latest : Json? = None
  for message in mock_server_state.sent_messages {
    if message.0 == type_code {
      latest = Some(message.1)
    }
  }
  latest
}
