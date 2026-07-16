///|
fn reset_npc_talk_ui_test_state() -> Unit {
  @npc_talk_ui.close_npc_talk_ui()
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
}

///|
fn load_quest_2090_quiz_text() -> String raise {
  let quest = @res.load_json("res://Quest/nx.json")
  match quest {
    { "Say.img": { "2090": { "1": { "0": String(text), .. }, .. }, .. }, .. } =>
      text
    _ => fail("res://Quest/nx.json missing Say.img/2090 phase 1 quiz text")
  }
}

///|
fn setup_npc_talk_resource_cache() -> Unit raise {
  let util_dlg_ex = @res.require_json("res://UI/UIWindow2.img/UtilDlgEx.json")
  let window_slice = @ui.load_ui_slice_resource(
    "res://UI/UIWindow2.img/UtilDlgEx/slice.json",
  )
  let resource = @npc_talk_ui.NpcTalkResource::from_resource(
    util_dlg_ex, window_slice,
  ) catch {
    err => fail("failed to parse UtilDlgEx: \{err.to_string()}")
  }
  @npc_talk_ui.cache_npc_talk_resource(resource)
}

///|
fn npc_talk_setup_scene() -> @app.App raise {
  let fixed_mouse_input_set = @system_set.named("fixed_mouse_input")
  let (app, _world) = @capture_app.new_graphics_test_app()
  let app = app
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @npc_talk_ui.npc_talk_ui_system(world) },
      system_name="npc_talk_ui_system",
    )
    .add_system(
      Update,
      fn(_world) {
        @inputs.mouse.pos = @math.Vec2(360.0, 260.0)
        @inputs.mouse.left_button = false
      },
      system_name="aaa_fixed_mouse_position_system",
      in_set=fixed_mouse_input_set,
    )
    .add_system(
      Update,
      fn(world) { @cursor.cursor_system(world) },
      system_name="cursor_system",
      after=[fixed_mouse_input_set],
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
    .add_system(
      Update,
      fn(world) { @ms_camera.camera_follow_system(world) },
      system_name="camera_follow_system",
    )
  @system.configure_display(800.0, 540.0, 1.0)
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  let cursor_data = @cursor.CursorAnimationData::load(
    "res://UI/Basic.img/Cursor/cursor_animation.json",
  )
  @cursor.init_cursor(Cursor(cursor_data))
  let camera_anchor = @entity.Entity()
  @ms_camera.setup_camera_entity(camera_anchor, center=@math.Vec2(0.0, 0.0))
  @ms_camera.set_follow_target(camera_anchor)

  setup_npc_talk_resource_cache()

  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id=103000000, portal_id=0),
  )

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_mouse_system(0.0)
  @inputs.mouse.pos = @math.Vec2(360.0, 260.0)
  @inputs.mouse.left_button = false

  @npc_talk_ui.open_npc_talk_ui({
    npc_id: 1052106,
    speaker: @npc.Speaker::NPC_LEFT,
    str: load_quest_2090_quiz_text() catch {
      err => fail("failed to load quest 2090 say text: \{err.to_string()}")
    },
    talk_action: @npc.TalkAction::SEND_SIMPLE(fn(_selection) { () }),
  })
  app
}

///|
test "npc_talk_ui quest 2090 keeps cursor above ui and grows with content" {
  reset_npc_talk_ui_test_state()
  defer reset_npc_talk_ui_test_state()

  let app = npc_talk_setup_scene()
  let capture = @capture_app.capture_after_frames(
    app,
    12,
    width=800,
    height=540,
    raw_delta=0.016,
  )

  let desc = @npc_talk_ui.describe_npc_talk_ui()
  json_inspect(desc, content={
    "open": true,
    "body_lines": [
      "Which of these monsters will you NOT see near Kerning City? ", "\r\r",
    ],
    "selections": [
      { "option": 0, "text": "1. Stump " },
      { "option": 1, "text": "2. Blue Mushroom " },
      { "option": 2, "text": "3. Slime " },
      { "option": 3, "text": "4. Ribbon Pig " },
      { "option": 4, "text": "5. Hector " },
    ],
    "button_count": 1,
    "choice_area_count": 5,
    "window_pos": { "x": 141, "y": 166 },
    "window_size": { "w": 519, "h": 221 },
    "window_rect": { "left": 141, "top": 166, "right": 660, "bottom": 387 },
    "z_range": { "min": 100100, "max": 100108 },
    "body_height": 149,
  })

  let z_max = match desc {
    { "z_range": { "max": Number(v, ..), .. }, .. } => v.to_int()
    _ => fail("missing z_range.max")
  }
  let body_height = match desc {
    { "body_height": Number(v, ..), .. } => v.to_int()
    _ => fail("missing body_height")
  }
  fn val_px(v : @selene_ui.Val) -> Double? {
    match v {
      @selene_ui.Val::Px(value) => Some(value)
      _ => None
    }
  }
  let mut has_cursor_node = false
  let mut has_window_material = false
  for it in @selene_ui.nodes().iter() {
    let (entity, node) = it
    let z = @selene_ui.z_indexes().get(entity).map_or(0, fn(it) { it.value })
    if z == 100100 && @selene_ui.material_nodes().contains(entity) {
      has_window_material = true
    }
    guard @selene_ui.ui_images().contains(entity) else { continue }
    guard z == @graphics.CURSOR_ZINDEX else { continue }
    guard val_px(node.left) is Some(left) else { continue }
    guard val_px(node.top) is Some(top) else { continue }
    if left >= 340.0 && left <= 370.0 && top >= 250.0 && top <= 270.0 {
      has_cursor_node = true
    }
  }

  assert_true(z_max < @graphics.CURSOR_ZINDEX)
  assert_true(body_height > 76)
  assert_true(has_window_material)
  assert_true(has_cursor_node)

  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/npc_talk_ui/npc_talk_ui_quest_2090.png",
    capture.png,
  )
}
