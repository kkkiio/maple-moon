///|
/// Reset mock server state recorded by capture tests.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.reset_mock_server()
/// ```
pub fn reset_mock_server() -> Unit {
  reset_mock_server_state()
}

///|
/// Emit a mock server message into the test-side game server bridge.
///
/// # Example
/// ```moonbit nocheck
/// @capture_app.emit_mock_server_message(message)
/// ```
pub fn[T : @server_proto.ServerMessage] emit_mock_server_message(
  message : T,
) -> Unit raise {
  emit_mock_server_state(T::type_code(), message.to_json())
}

///|
/// Return how many client messages with `type_code` the mock server received.
///
/// # Example
/// ```moonbit nocheck
/// let count = @capture_app.mock_server_sent_count(type_code)
/// ```
pub fn mock_server_sent_count(type_code : Int) -> Int {
  mock_server_sent_count_internal(type_code)
}

///|
/// Return the latest client message JSON recorded by the mock server.
///
/// # Example
/// ```moonbit nocheck
/// let latest = @capture_app.mock_server_latest_sent_json(type_code)
/// ```
pub fn mock_server_latest_sent_json(type_code : Int) -> Json? {
  mock_server_latest_sent_json_internal(type_code)
}
