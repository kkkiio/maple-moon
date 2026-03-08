///|
fn load_json_from_file(path : String) -> Json {
  (@fs.read_file_to_string(path) |> @json.parse) catch {
    _ => panic()
  }
}

///|
fn load_world_map_ui_json_for_test() -> Json raise {
  let raw = load_json_from_file("assets/ui/UIWindow2.img/WorldMap.json")
  let spritesheet_names = [
    "BtAll", "BtAnother", "BtAnotherWorld", "BtAutoFly_1", "BtAutoFly_2", "BtBefore",
    "BtNext", "BtNaviRegister", "BtSearch", "NoticeIcon", "WorldMapSearch",
  ]
  let spritesheet_jsons : Map[String, @resource.SpritesheetMetadata] = Map::new()
  for name in spritesheet_names {
    let meta_json = load_json_from_file(
      "assets/spritesheets/UI/UIWindow2.img/WorldMap/\{name}.json",
    )
    let meta : @resource.SpritesheetMetadata = @json.from_json(meta_json)
    spritesheet_jsons.set(
      "spritesheets/UI/UIWindow2.img/WorldMap/\{name}",
      meta,
    )
  }
  @resource.patch_image(raw, spritesheet_jsons, base_url="/assets")
}

///|
fn load_world_map_tooltip_json_for_test() -> Json raise {
  let raw : Json = match
    load_json_from_file("assets/ui/UIWindow2.img/ToolTip.json") {
    { "WorldMap": world_map_json, .. } => { "WorldMap": world_map_json }
    _ => fail("missing ToolTip.WorldMap")
  }
  let meta_json = load_json_from_file(
    "assets/spritesheets/UI/UIWindow2.img/ToolTip/WorldMap.json",
  )
  let spritesheet_jsons : Map[String, @resource.SpritesheetMetadata] = Map::new()
  let meta : @resource.SpritesheetMetadata = @json.from_json(meta_json)
  spritesheet_jsons.set("spritesheets/UI/UIWindow2.img/ToolTip/WorldMap", meta)
  @resource.patch_image(raw, spritesheet_jsons, base_url="/assets")
}

///|
fn setup_world_map_ui_scene() -> Unit {
  @world_map_ui.reset_world_map_ui_for_test()
  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(920.0)
    .with_canvas_height(640.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@world_map_ui.world_map_ui_system)
    .add_system(@io_service.io_system, system_name="io_system"),
  )
  @world_map_ui.set_world_map_ui_json_for_test(
    load_world_map_ui_json_for_test() catch {
      _ => panic()
    },
  )
  @world_map_ui.set_world_map_tooltip_json_for_test(
    load_world_map_tooltip_json_for_test() catch {
      _ => panic()
    },
  )
  @world_map_ui.set_map_helper_world_map_json_for_test(
    load_json_from_file("assets/spritesheets/Map/MapHelper.img/worldMap.json"),
  )
  @world_map_ui.set_world_map_json_for_test(
    "WorldMap",
    load_json_from_file("assets/map/WorldMap/WorldMap.img.json"),
  )
  @world_map_ui.set_world_map_json_for_test(
    "WorldMap010",
    load_json_from_file("assets/map/WorldMap/WorldMap010.img.json"),
  )
  @world_map_ui.set_world_map_json_for_test(
    "WorldMap011",
    load_json_from_file("assets/map/WorldMap/WorldMap011.img.json"),
  )
  @world_map_ui.set_world_map_panel_position_for_test(20, 16)
  @world_map_ui.set_current_map(100000000, "Southperry", "Victoria Island")
  @world_map_ui.set_world_map_visible(true)
  for _ in 0..<80 {
    @capture_app.run_loop(0.016)
  }
}

///|
test "world map ui opens at current root and reopens from root page" {
  defer @world_map_ui.reset_world_map_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_world_map_ui_scene()
  json_inspect(@world_map_ui.get_world_map_debug_state_for_test(), content={
    "visible": true,
    "search_visible": false,
    "current_world_name": "WorldMap010",
    "current_user_root_world_name": "WorldMap010",
    "hovered_spot_index": null,
    "hovered_link_index": null,
    "has_page": true,
    "page_parent_map": "WorldMap",
  })

  @world_map_ui.open_world_map_page_for_test("WorldMap011")
  for _ in 0..<20 {
    @capture_app.run_loop(0.016)
  }
  json_inspect(@world_map_ui.get_world_map_debug_state_for_test(), content={
    "visible": true,
    "search_visible": false,
    "current_world_name": "WorldMap011",
    "current_user_root_world_name": "WorldMap010",
    "hovered_spot_index": null,
    "hovered_link_index": null,
    "has_page": true,
    "page_parent_map": "WorldMap010",
  })

  @world_map_ui.set_world_map_visible(false)
  @world_map_ui.set_world_map_visible(true)
  for _ in 0..<20 {
    @capture_app.run_loop(0.016)
  }
  json_inspect(@world_map_ui.get_world_map_debug_state_for_test(), content={
    "visible": true,
    "search_visible": false,
    "current_world_name": "WorldMap010",
    "current_user_root_world_name": "WorldMap010",
    "hovered_spot_index": null,
    "hovered_link_index": null,
    "has_page": true,
    "page_parent_map": "WorldMap",
  })
}

///|
test "world map ui escape closes search before navigating to parent" {
  defer @world_map_ui.reset_world_map_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_world_map_ui_scene()
  @world_map_ui.open_world_map_page_for_test("WorldMap011")
  for _ in 0..<20 {
    @capture_app.run_loop(0.016)
  }
  @world_map_ui.set_world_map_search_visible_for_test(true)
  @world_map_ui.handle_world_map_escape_for_test()
  json_inspect(@world_map_ui.get_world_map_debug_state_for_test(), content={
    "visible": true,
    "search_visible": false,
    "current_world_name": "WorldMap011",
    "current_user_root_world_name": "WorldMap010",
    "hovered_spot_index": null,
    "hovered_link_index": null,
    "has_page": true,
    "page_parent_map": "WorldMap010",
  })
  @world_map_ui.handle_world_map_escape_for_test()
  for _ in 0..<12 {
    @capture_app.run_loop(0.016)
  }
  json_inspect(@world_map_ui.get_world_map_debug_state_for_test(), content={
    "visible": true,
    "search_visible": false,
    "current_world_name": "WorldMap010",
    "current_user_root_world_name": "WorldMap010",
    "hovered_spot_index": null,
    "hovered_link_index": null,
    "has_page": true,
    "page_parent_map": "WorldMap",
  })
}

///|
test "world map ui renders root page snapshot" {
  defer @world_map_ui.reset_world_map_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_world_map_ui_scene()
  @capture_app.snapshot(
    "src/test/world_map_ui_test/__snapshot__/world_map_ui_root.png",
  )
}

///|
test "world map ui renders hovered spot tooltip snapshot" {
  defer @world_map_ui.reset_world_map_ui_for_test()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  setup_world_map_ui_scene()
  @world_map_ui.set_hovered_spot_index_for_test(Some(7))
  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
  @capture_app.snapshot(
    "src/test/world_map_ui_test/__snapshot__/world_map_ui_hover_spot.png",
  )
}
