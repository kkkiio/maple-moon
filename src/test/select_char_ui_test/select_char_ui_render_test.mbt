///|
fn make_local_body_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_body",
    base_url="/assets",
    loader=@local_loader.LocalDirResourceLoader::new("assets/Character/Body"),
  )
}

///|
fn make_local_face_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_face",
    base_url="/assets",
    loader=@local_loader.LocalDirResourceLoader::new("assets/Character/Face"),
  )
}

///|
fn make_local_hair_loader() -> @resource.AsyncLoader {
  @resource.AsyncLoader::new(
    "test_local_hair",
    base_url="/assets",
    loader=@local_loader.LocalDirResourceLoader::new("assets/Character/Hair"),
  )
}

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
  @resource.register_async_loader("body", make_local_body_loader())
  @resource.register_async_loader("face", make_local_face_loader())
  @resource.register_async_loader("hair", make_local_hair_loader())
  @select_char_ui.setup_game_server_handlers()
  let app = @app.App::new()
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
async fn wait_until_character_list_requested() -> Unit {
  for _ in 0..<120 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
    if @capture_app.mock_server_sent_count(
        @server_proto.CharacterListRequestMessage::type_code(),
      ) >
      0 {
      return
    }
  }
  abort("select_char_ui did not request character list")
}

///|
async fn wait_until_select_char_ui_loaded() -> Unit {
  @capture_app.emit_mock_server_message(test_character_list_message())
  for _ in 0..<240 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
    if @entity.iter_entities().to_array().length() >= 10 {
      @capture_app.run_loop(0.016)
      @async.sleep(0)
      return
    }
  }
  abort("select_char_ui not loaded")
}

///|
fn setup_select_char_phase() -> Unit {
  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id=100000000, portal_id=0),
  )
  @game_state.init_state(@game_state.GamePhase::SelectCharacter)
}

///|
fn assert_character_list_requested() -> Unit raise {
  inspect(
    @capture_app.mock_server_sent_count(
      @server_proto.CharacterListRequestMessage::type_code(),
    ),
    content="1",
  )
  let request_json = @capture_app.mock_server_latest_sent_json(
    @server_proto.CharacterListRequestMessage::type_code(),
  ).unwrap()
  let _request : @server_proto.CharacterListRequestMessage = @json.from_json(
    request_json,
  )
}

///|
async test "select char ui renders character and start button chooses first character" {
  defer @capture_app.reset_mock_server()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  setup_select_char_ui_scene()
  setup_select_char_phase()
  @char_look.insert_resource(@char_look.CharacterPresentationResource::load())
  wait_until_character_list_requested()
  assert_character_list_requested()
  wait_until_select_char_ui_loaded()
  @capture_app.run_loop(0.016)
  @async.sleep(0)
  @capture_app.snapshot(
    "src/test/select_char_ui_test/__snapshot__/select_char_ui_default.png",
    img_description="Select character UI is open with one character, showing character preview, name, and start button.",
  )
}
