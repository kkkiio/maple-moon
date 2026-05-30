///|
fn setup_local_loaders() -> Unit {
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
  @app.App()
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
fn setup_scene(app : @app.App) -> Unit {
  @game_state.init_state(@game_state.GamePhase::GameSetup)

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)

  setup_local_loaders()
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
  setup_scene(app)

  let captures = app.run_frames_capture(12, raw_delta=0.016)

  @capture_app.snapshot(
    "src/test/quest_log_ui_test/__snapshot__/quest_log_ui_in_progress.png",
    captures[captures.length() - 1].png,
    visual_desc="Quest log UI showing the in-progress tab with a list of active quests.",
  )

  let click_row_ok = @console.click_registered_ui(
    "quest_log", "row.in_progress.3",
  )
  assert_true(click_row_ok is { "ok": true, .. })
  let captures2 = app.run_frames_capture(3, raw_delta=0.016)
  @capture_app.snapshot(
    "src/test/quest_log_ui_test/__snapshot__/quest_log_ui_in_progress_second_selected.png",
    captures2[captures2.length() - 1].png,
    visual_desc="Quest log UI with the second quest in the in-progress list selected, displaying its details.",
  )

  let click_ok = @console.click_registered_ui("quest_log", "tab.completed")
  assert_true(click_ok is { "ok": true, .. })
  let captures3 = app.run_frames_capture(3, raw_delta=0.016)
  @capture_app.snapshot(
    "src/test/quest_log_ui_test/__snapshot__/quest_log_ui_completed.png",
    captures3[captures3.length() - 1].png,
    visual_desc="Quest log UI showing the completed tab with a list of finished quests.",
  )
}

///|
test "quest_log_ui closes on escape" {
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
