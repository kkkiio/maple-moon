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
fn setup_select_char_ui_scene() -> Unit {
  @select_char_ui.reset_select_char_ui_for_test()
  @resource.set_body_loader(make_local_body_loader())
  @resource.set_face_loader(make_local_face_loader())
  @resource.set_hair_loader(make_local_hair_loader())
  @capture_app.init_app(
    @system.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      @select_char_ui.select_char_ui_system,
      system_name="select_char_ui_system",
    ),
  )
}

///|
fn wait_until_select_char_ui_loaded() -> Unit {
  for _ in 0..<10 {
    if @select_char_ui.get_select_char_ui_debug_state_for_test()
      is { "loaded": true, .. } {
      return
    }
    @capture_app.run_loop(0.016)
  }
  abort("select_char_ui not loaded")
}

///|
async test "select char ui renders character and name" {
  defer @select_char_ui.reset_select_char_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_select_char_ui_scene()
  let mod = @char_look.CharLookMod::load()
  @select_char_ui.init_select_char_ui_for_test(mod)
  wait_until_select_char_ui_loaded()
  json_inspect(@select_char_ui.get_select_char_ui_debug_state_for_test(), content={
    "loaded": true,
    "character_count": 1,
    "character_names": ["kkkiio"],
    "selected_slot": null,
    "last_selected_character_id": null,
  })
  @capture_app.run_loop(0.016)
  @capture_app.snapshot(
    "src/test/select_char_ui_test/__snapshot__/select_char_ui_default.png",
  )
}

///|
async test "select char ui select button chooses first character" {
  defer @select_char_ui.reset_select_char_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_select_char_ui_scene()
  let mod = @char_look.CharLookMod::load()
  @select_char_ui.init_select_char_ui_for_test(mod)
  wait_until_select_char_ui_loaded()
  @inputs.mouse.pos = @selene_math.Vec2D(620.0, 410.0)
  @capture_app.run_loop(0.016)
  @inputs.mouse.left_button = true
  @capture_app.run_loop(0.016)
  @inputs.mouse.left_button = false
  @capture_app.run_loop(0.016)
  @capture_app.run_loop(0.016)
  json_inspect(@select_char_ui.get_select_char_ui_debug_state_for_test(), content={
    "loaded": true,
    "character_count": 1,
    "character_names": ["kkkiio"],
    "selected_slot": null,
    "last_selected_character_id": [1],
  })
}
