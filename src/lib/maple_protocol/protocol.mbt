///|
/// Message to be sent to the server
pub(open) trait ClientMessage: ToJson + @json.FromJson {
  type_code() -> Int
}

///|
/// Message to be sent to the server
pub(open) trait ServerMessage: ToJson + @json.FromJson {
  type_code() -> Int
}
