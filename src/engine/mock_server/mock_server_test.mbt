///|
test "runtime facade forwards messages, handlers, and ticks" {
  let server = @mock_server.MockServer()
  @game_server.install(server)
  @game_server.send(@server_proto.CharacterListRequestMessage(()))
  assert_eq(
    server.sent_count(@server_proto.CharacterListRequestMessage::type_code()),
    1,
  )
  @game_server.init_server()
  assert_eq(
    server.sent_count(@server_proto.CharacterListRequestMessage::type_code()),
    0,
  )
  let received = Ref(false)
  @game_server.add_server_message_handler(
    "character_list",
    @server_proto.CharacterListMessage::type_code(),
    fn(payload) raise {
      let message : @server_proto.CharacterListMessage = @json.from_json(
        payload,
      )
      assert_eq(message.characters.length(), 0)
      received.val = true
    },
  )
  @game_server.send(@server_proto.CharacterListRequestMessage(()))
  let request_json = server
    .latest_sent_json(@server_proto.CharacterListRequestMessage::type_code())
    .unwrap()
  let _ : @server_proto.CharacterListRequestMessage = @json.from_json(
    request_json,
  )
  server.emit(@server_proto.CharacterListMessage::{ characters: [] }) catch {
    err => fail("failed to emit character list: \{err.to_string()}")
  }
  assert_true(received.val)
  @game_server.server_system(1.0 / 60.0)
  assert_eq(server.tick_count(), 1)
}
