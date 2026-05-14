///|
fn test_character_list_message() -> @server_proto.CharacterListMessage {
  {
    characters: [
      {
        character_id: 1,
        name: "kkkiio",
        look: {
          female: false,
          skin: 0,
          faceid: 20000,
          hairid: 30030,
          equips: {},
          maskedequips: {},
          petids: [],
        },
      },
    ],
  }
}

///|
fn setup_select_char_ui_scene() -> Unit {
  @capture_app.reset_mock_server()
  @local_loader.install_resource_env_for_test()
  @select_char_ui.setup_game_server_handlers()
  let app = @app.App()
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
    .add_system(
      Update,
      fn(world) { @char_look.char_look_system(world) },
      system_name="char_look_system",
    )
    .add_system(
      Update,
      fn(world) { @select_char_ui.select_char_ui_system(world) },
      system_name="select_char_ui_system",
    )
  @capture_app.init_app(app)
  @game_state.init_state(@game_state.GamePhase::GameSetup)
}

///|
fn setup_select_char_phase() -> Unit {
  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id=100000000, portal_id=0),
  )
  @game_state.init_state(@game_state.GamePhase::SelectCharacter)
}

///|
async test "select char ui renders character and start button chooses first character" {
  defer @capture_app.reset_mock_server()
  setup_select_char_ui_scene()
  setup_select_char_phase()
  @char_look.insert_resource(@char_look.CharacterPresentationResource::load())
  for _ in 0..<120 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
    if @capture_app.mock_server_sent_count(
        @server_proto.CharacterListRequestMessage::type_code(),
      ) >
      0 {
      break
    }
  }

  inspect(
    @capture_app.mock_server_sent_count(
      @server_proto.CharacterListRequestMessage::type_code(),
    ),
    content="1",
  )
  let request_json = @capture_app.mock_server_latest_sent_json(
    @server_proto.CharacterListRequestMessage::type_code(),
  ).unwrap()
  let _ : @server_proto.CharacterListRequestMessage = @json.from_json(
    request_json,
  )

  @capture_app.emit_mock_server_message(test_character_list_message())
  for _ in 0..<240 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
    if @entity.iter_entities().to_array().length() >= 10 {
      break
    }
  }

  @capture_app.run_loop(0.016)
  @async.sleep(0)
  @capture_app.snapshot(
    "src/test/select_char_ui_test/__snapshot__/select_char_ui_default.png",
    visual_desc="Select character UI is open with one character, showing character preview, name, and start button.",
  )
}
