///|
pub fn init_server() -> Unit {
  @capture_app.reset_mock_server_state()
}

///|
#callsite(autofill(loc))
pub fn[T : @server_proto.ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  ignore(log_level)
  ignore(loc)
  @capture_app.record_mock_server_sent_message(
    T::type_code(),
    message.to_json(),
  )
}

///|
pub fn add_server_message_handler(
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  ignore(name)
  @capture_app.add_mock_server_handler(type_code, handler)
}

///|
pub fn server_system(_delta : Double) -> Unit {

}
