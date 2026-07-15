///|
fn setup_quest_log_resource() -> Unit {
  let (quest_resource, _) = @quest.load_quest_resource()
  @quest_log.setup(quest_resource)
}

///|
fn reset_quest_log_ui_test_state() -> Unit {
  @console.clear_input_injection()
  @quest_log_ui.close_quest_log_ui()
  @entity.iter_entities().each(fn(entity) { entity.destroy() })
  @sprite.sprites().clear()
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
}

///|
fn create_app() -> @app.App {
  let (app, _world) = @capture_app.new_graphics_test_app()
  app
  .with_viewport_width(800.0)
  .with_viewport_height(540.0)
  .add_plugin(@plugins.default_plugin)
  .add_system(
    First,
    fn(world) { @console.console_input_injection_system(world) },
    system_name="console_input_injection_system",
  )
  .add_system(
    Update,
    fn(world) { @quest_log_ui.quest_log_ui_system(world) },
    system_name="quest_log_ui_system",
  )
  .add_system(
    Update,
    fn(world) { @io_service.io_system(world) },
    system_name="io_system",
  )
}

///|
fn quest_log_setup_scene(app : @app.App) -> Unit {
  @game_state.init_state(@game_state.GamePhase::GameSetup)

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)

  setup_quest_log_resource()
  @quest_log.handle_player_quest_info({
    started: [(2085, ""), (2091, "3")],
    completed: [(2000, 123456)],
  })
  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id=100000000, portal_id=0),
  )
  // Flush one frame of empty input before opening UI to avoid stale key edge states.
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  app.run_frames(1, raw_delta=0.016)
  @quest_log_ui.open_quest_log_ui()
}

///|
test "quest_log_ui renders in-progress & completed tab" {
  reset_quest_log_ui_test_state()
  defer reset_quest_log_ui_test_state()

  let app = create_app()
  quest_log_setup_scene(app)

  let capture = @capture_app.capture_after_frames(
    app,
    12,
    width=800,
    height=540,
    raw_delta=0.016,
  )

  json_inspect(@quest_log.get_snapshot(), content={
    "in_progress": [
      {
        "quest_id": 2085,
        "name": "In search of Wing the Fairy",
        "progress_data": "",
        "phase": 1,
        "phase_description": "Icarus had failed to make the flying balloon, but his never-ending quest for flight remains. This time he wants to deviate from the scientific approach to flight and opts for the magical approach, and asks me to see his best friend #b#p1032106##k at Ellinia, the town of fairies. Apparently Wing the Fairy knows the way to make #b'#t4031163#'#k...I'll need to see that fairy at Ellinia for Icarus's sake.",
      },
      {
        "quest_id": 2091,
        "name": "I'm Bored 2",
        "progress_data": "3",
        "phase": 1,
        "phase_description": "I answered all of Icarus's questions, but he still seemed bored out of his mind. He asked me if I could get him a toy that he could play around with. \\n\\n #t4000003# #b#c4000003##k/40 \\n#t4000004# #b#c4000004##k/40",
      },
    ],
    "completed": [
      {
        "quest_id": 2000,
        "name": "Fixing Blackbull's House",
        "completion_time": "123456",
      },
    ],
  })
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/quest_log_ui/quest_log_ui_in_progress.png",
    capture.png,
  )

  let click_row_ok = @console.click_registered_ui(
    "quest_log", "row.in_progress.3",
  )
  json_inspect(click_row_ok, content={
    "ok": true,
    "code": "CLICK_SENT",
    "message": "click event sent",
    "package": "quest_log",
    "name": "row.in_progress.3",
    "click_pos": { "x": 452.5, "y": 300 },
    "rect": { "x": 330, "y": 290, "w": 245, "h": 20 },
  })
  let capture2 = @capture_app.capture_after_frames(
    app,
    3,
    width=800,
    height=540,
    raw_delta=0.016,
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/quest_log_ui/quest_log_ui_in_progress_second_selected.png",
    capture2.png,
  )

  let click_ok = @console.click_registered_ui("quest_log", "tab.completed")
  json_inspect(click_ok, content={
    "ok": true,
    "code": "CLICK_SENT",
    "message": "click event sent",
    "package": "quest_log",
    "name": "tab.completed",
    "click_pos": { "x": 478.5, "y": 195 },
    "rect": { "x": 451, "y": 185, "w": 55, "h": 20 },
  })
  let capture3 = @capture_app.capture_after_frames(
    app,
    3,
    width=800,
    height=540,
    raw_delta=0.016,
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/quest_log_ui/quest_log_ui_completed.png",
    capture3.png,
  )
}

///|
test "quest_log_ui closes on escape" {
  let (app, _world) = @capture_app.new_graphics_test_app()
  ignore(app)
  reset_quest_log_ui_test_state()
  defer reset_quest_log_ui_test_state()
  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id=100000000, portal_id=0),
  )
  @quest_log_ui.open_quest_log_ui()
  let pressed = @inputs.empty_input_snapshot()
  pressed.pressed_keys.add(@inputs.Code::Escape)
  @inputs.apply_input_snapshot(pressed)
  @inputs.advanced_key_system(0.0)
  @quest_log_ui.quest_log_ui_system(@ecs.require_current_world())
  assert_false(@quest_log_ui.is_quest_log_ui_open())
}
