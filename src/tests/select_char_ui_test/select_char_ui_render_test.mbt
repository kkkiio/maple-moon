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
fn setup_select_char_ui_scene(
  script? : (@ecs.World) -> Unit = fn(_world) {  },
) -> @app.App {
  @capture_app.reset_mock_server()
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
    .add_system(
      Update,
      fn(world) { script(world) },
      system_name="select_char_ui_test_script",
    )
  @ecs.set_current_world(app.world())
  @system.configure_display(800.0, 600.0, 1.0)
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  app
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
  let emitted_character_list = Ref(false)
  let app = setup_select_char_ui_scene(script=fn(world) {
    ignore(world)
    if !emitted_character_list.val &&
      @capture_app.mock_server_sent_count(
        @server_proto.CharacterListRequestMessage::type_code(),
      ) >
      0 {
      @capture_app.emit_mock_server_message(test_character_list_message()) catch {
        err => abort("failed to emit character list: \{err.to_string()}")
      }
      emitted_character_list.val = true
    }
  })
  setup_select_char_phase()
  @char_look.insert_resource(@char_look.CharacterPresentationResource::load())
  let capture = @capture_app.capture_after_frames(
    app,
    360,
    width=800,
    height=600,
    raw_delta=0.016,
  )

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

  assert_true(emitted_character_list.val)
  assert_true(@entity.iter_entities().to_array().length() >= 10)

  @capture_app.snapshot(
    "src/tests/select_char_ui_test/__snapshot__/select_char_ui_default.png",
    capture.png,
    visual_desc="Select character UI is open with one character, showing character preview, name, and start button.",
  )
}
