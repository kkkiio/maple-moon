///|
fn setup_local_loaders() -> Unit {
  @resource.set_quest_loader(@local_loader.make_local_quest_loader())
  @resource.set_ui_window_2_loader(
    @resource.AsyncLoader::new(
      "test_local_ui_window_2",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new(
        "assets/ui/UIWindow2.img",
      ),
    ),
  )
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
async fn setup_scene() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      First,
      fn(_world) { @console.console_input_injection_system(@time.delta()) },
      system_name="console_input_injection_system",
    )
    .add_system(
      Update,
      fn(_world) { @quest_log_ui.quest_log_ui_system(@time.delta()) },
      system_name="quest_log_ui_system",
    )
    .add_system(
      Update,
      fn(_world) { @io_service.io_system(@time.delta()) },
      system_name="io_system",
    )
  @capture_app.init_app(app)

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)

  setup_local_loaders()
  ignore(@quest.Module::load(@inventory.Inventory::new(), fn(_args) { () }))
  @quest_log.handle_player_quest_info({
    started: [(1000, "3")],
    completed: [(2000, 123456)],
  })
  @game_state.game_state.phase = @game_state.GamePhase::GameActive(
    map_id=100000000,
    portal_id=0,
  )
  // Flush one frame of empty input before opening UI to avoid stale key edge states.
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @capture_app.run_loop(0.016)
  @quest_log_ui.open_quest_log_ui()
  for _ in 0..<12 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "quest_log_ui renders in-progress & completed tab" {
  reset_quest_log_ui_test_state()
  defer reset_quest_log_ui_test_state()
  defer @quest.clear_active_module()
  setup_scene()

  @capture_app.snapshot(
    "src/test/quest_log_ui_test/__snapshot__/quest_log_ui_in_progress.png",
    expect="Quest Log window is open and readable. IN-PROGRESS is the active highlighted tab. COMPLETED is visible but inactive.",
  )

  let click_ok = @console.click_registered_ui("quest_log", "tab.completed")
  assert_true(click_ok is { "ok": true, .. })
  for _ in 0..<3 {
    @capture_app.run_loop(0.016)
  }
  @capture_app.snapshot(
    "src/test/quest_log_ui_test/__snapshot__/quest_log_ui_completed.png",
    expect="Quest Log window remains open after clicking the COMPLETED tab. COMPLETED is the active highlighted tab, and IN-PROGRESS is inactive.",
  )
}

///|
test "quest_log_ui closes on escape" {
  reset_quest_log_ui_test_state()
  defer reset_quest_log_ui_test_state()
  @game_state.game_state.phase = @game_state.GamePhase::GameActive(
    map_id=100000000,
    portal_id=0,
  )
  @quest_log_ui.open_quest_log_ui()
  let pressed = @inputs.empty_input_snapshot()
  pressed.pressed_keys.add(@inputs.Code::Escape)
  @inputs.apply_input_snapshot(pressed)
  @inputs.advanced_key_system(0.0)
  @quest_log_ui.quest_log_ui_system(0.016)
  assert_false(@quest_log_ui.is_quest_log_ui_open())
}
