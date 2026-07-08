///|
/// Message to be sent to the server
pub(open) trait ClientMessage: ToJson + @json.FromJson {
  fn type_code() -> Int
}

///|
/// Message to be sent to the server
pub(open) trait ServerMessage: ToJson + @json.FromJson {
  fn type_code() -> Int
}
