///|
fn setup_local_loaders() -> Unit {
  @resource.register_async_loader(
    "ui_window_2",
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
fn reset_npc_talk_ui_test_state() -> Unit {
  @npc_talk_ui.close_npc_talk_ui()
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.advanced_mouse_system(0.0)
}

///|
fn load_quest_2090_quiz_text() -> String raise {
  let say_2090 = @fs.read_file_to_string("assets/Quest/Say.img/2090.json")
    |> @json.parse
  match say_2090 {
    { "1": { "0": String(text), .. }, .. } => text
    _ => fail("assets/Quest/Say.img/2090.json missing phase 1 quiz text")
  }
}

///|
async fn setup_npc_talk_resource_cache() -> Unit {
  let util_dlg_ex = @resource.get_async_loader("ui_window_2").load_resource([
    "UtilDlgEx",
  ])
  let resource = @npc_talk_ui.NpcTalkResource::from_resource(util_dlg_ex) catch {
    err => fail("failed to parse UtilDlgEx: \{err.to_string()}")
  }
  @npc_talk_ui.cache_npc_talk_resource(resource)
}

///|
async fn setup_scene() -> Unit {
  let app = @app.App::new()
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
      fn(world) { @cursor.cursor_system(world) },
      system_name="cursor_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
  @capture_app.init_app(app)
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  let camera_anchor = @entity.Entity::new()
  @ms_camera.setup_camera_entity(camera_anchor, center=@math.Vec2D(0.0, 0.0))
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())

  setup_local_loaders()
  setup_npc_talk_resource_cache()

  @game_state.init_state(@game_state.GamePhase::GameActive(
    map_id=103000000,
    portal_id=0,
  ))

  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_mouse_system(0.0)
  @inputs.mouse.pos = @math.Vec2D(360.0, 260.0)
  @inputs.mouse.left_button = false

  @npc_talk_ui.open_npc_talk_ui({
    npc_id: 1052106,
    speaker: @npc.Speaker::NPC_LEFT,
    str: load_quest_2090_quiz_text() catch {
      err => fail("failed to load quest 2090 say text: \{err.to_string()}")
    },
    talk_action: @npc.TalkAction::SEND_SIMPLE(fn(_selection) { () }),
  })

  for _ in 0..<12 {
    @inputs.mouse.pos = @math.Vec2D(360.0, 260.0)
    @inputs.mouse.left_button = false
    @capture_app.run_loop(0.016)
  }
}

///|
async test "npc_talk_ui quest 2090 keeps cursor above ui and grows with content" {
  reset_npc_talk_ui_test_state()
  defer reset_npc_talk_ui_test_state()

  setup_scene()

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
  fn val_to_json(v : @selene_ui.Val) -> Json {
    match v {
      @selene_ui.Val::Px(value) => { "kind": "px", "value": value.to_json() }
      @selene_ui.Val::Percent(value) =>
        { "kind": "percent", "value": value.to_json() }
      @selene_ui.Val::Auto => { "kind": "auto" }
    }
  }
  let cursor_nodes : Array[Json] = @selene_ui.nodes()
    .iter()
    .map(fn(it) {
      let (entity, node) = it
      let z = match @selene_ui.z_indexes().get(entity) {
        Some(v) => v.value.to_json()
        None => Json::null()
      }
      let has_image = @selene_ui.ui_images().contains(entity)
      (
        {
          "z": z,
          "left": val_to_json(node.left),
          "top": val_to_json(node.top),
          "has_image": has_image.to_json(),
        } : Json)
    })
    .collect()
  json_inspect(cursor_nodes, content=[
    {
      "z": 100100,
      "left": { "kind": "px", "value": 141 },
      "top": { "kind": "px", "value": 166 },
      "has_image": true,
    },
    {
      "z": 100100,
      "left": { "kind": "px", "value": 141 },
      "top": { "kind": "px", "value": 194 },
      "has_image": true,
    },
    {
      "z": 100100,
      "left": { "kind": "px", "value": 141 },
      "top": { "kind": "px", "value": 343 },
      "has_image": true,
    },
    {
      "z": 100102,
      "left": { "kind": "px", "value": 241 },
      "top": { "kind": "px", "value": 361 },
      "has_image": true,
    },
    {
      "z": 100104,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 185 },
      "has_image": false,
    },
    {
      "z": 100105,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 217 },
      "has_image": false,
    },
    {
      "z": 100105,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 240 },
      "has_image": false,
    },
    {
      "z": 100105,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 263 },
      "has_image": false,
    },
    {
      "z": 100105,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 286 },
      "has_image": false,
    },
    {
      "z": 100105,
      "left": { "kind": "px", "value": 307 },
      "top": { "kind": "px", "value": 309 },
      "has_image": false,
    },
    {
      "z": 100108,
      "left": { "kind": "px", "value": 150 },
      "top": { "kind": "px", "value": 363 },
      "has_image": true,
    },
    {
      "z": 200000,
      "left": { "kind": "px", "value": 360 },
      "top": { "kind": "px", "value": 257 },
      "has_image": true,
    },
  ])

  let mut has_cursor_node = false
  for entry in cursor_nodes {
    match entry {
      {
        "z": Number(z, ..),
        "left": { "kind": "px", "value": Number(left, ..), .. },
        "top": { "kind": "px", "value": Number(top, ..), .. },
        "has_image": True,
        ..
      } =>
        if z.to_int() == @graphics.CURSOR_ZINDEX &&
          left >= 340.0 &&
          left <= 370.0 &&
          top >= 250.0 &&
          top <= 270.0 {
          has_cursor_node = true
        }
      _ => ()
    }
  }

  assert_true(z_max < @graphics.CURSOR_ZINDEX)
  assert_true(body_height > 76)
  assert_true(has_cursor_node)

  @capture_app.snapshot(
    "src/test/npc_talk_ui_test/__snapshot__/npc_talk_ui_quest_2090.png",
    img_description="NPC talk UI for quest 2090 quiz is open with multiple options. The cursor rendered by cursor_system is visible on top of the dialog and not occluded by UI layers. The window is tall enough to avoid clipping the content.",
  )
}
