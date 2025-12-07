///|
/// Message to be sent to the server
pub(open) trait ClientMessage: ToJson + @json.FromJson {
  type_code() -> Int
}
