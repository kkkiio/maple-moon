///|
fn load_json_from_file(path : String) -> Json {
  (@fs.read_file_to_string(path) |> @json.parse) catch {
    _ => panic()
  }
}

///|
fn load_real_mini_map_ui_json() -> Json {
  load_json_from_file("assets/ui/UIWindow2.img/MiniMap.json")
}

///|
fn load_real_map_helper_minimap_json() -> Json {
  load_json_from_file("assets/spritesheets/Map/MapHelper.img/minimap.json")
}

///|
fn make_test_runtime_resource_with_canvas(
  canvas_path : String,
  canvas_w : Int,
  canvas_h : Int,
  portals? : Array[@map.MiniMapPortal] = [],
) -> @map.MiniMapRuntimeResource {
  let mini_map_json : Json = {
    "mag": 0,
    "centerX": 0,
    "centerY": 0,
    "canvas": {
      "__i": canvas_path,
      "__w": canvas_w,
      "__h": canvas_h,
      "__off": [64, 27],
      "origin": [0, 0],
    },
  }
  let mini_map_resource : @map.MiniMapResource = @json.from_json(mini_map_json) catch {
    _ => panic()
  }
  @map.MiniMapRuntimeResource::load(mini_map_resource, portals)
}

///|
fn setup_mini_map_ui_scene_with_data(
  map_id : Int,
  map_name : String,
  street_name : String,
  mini_map_resource : @map.MiniMapRuntimeResource?,
) -> Unit {
  @mini_map_ui.set_minimap_json_for_test(load_real_mini_map_ui_json())
  @mini_map_ui.set_map_helper_minimap_json_for_test(
    load_real_map_helper_minimap_json(),
  )
  @mini_map_ui.clear_current_map()
  let app = @app.App::new()
    .with_viewport_width(420.0)
    .with_viewport_height(240.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(Update, fn(_world) {
      @mini_map_ui.mini_map_ui_system(@time.delta())
    })
  @capture_app.init_app(app)
  @mini_map_ui.set_current_map(map_id, map_name, street_name, mini_map_resource)

  for _ in 0..<8 {
    @capture_app.run_loop(0.016)
  }
}

///|
test "mini map ui renders normal frame" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  setup_mini_map_ui_scene_with_data(
    120010000,
    "Nautilus",
    "120010000",
    Some(
      make_test_runtime_resource_with_canvas(
        "/assets/images/Map/30691.png", 269, 49,
      ),
    ),
  )
  @capture_app.snapshot(
    "src/test/mini_map_ui_test/__snapshot__/mini_map_ui_normal.png",
  )
}

///|
fn load_real_minimap_runtime_resource_100030000() -> @map.MiniMapRuntimeResource {
  let map_json = (@fs.read_file_to_string("assets/map/map1/100030000.img.json")
  |> @json.parse) catch {
    _ => panic()
  }
  let mini_map_resource : @map.MiniMapResource = try {
    match map_json {
      { "miniMap": mini_map_json, .. } => @json.from_json(mini_map_json)
      _ => panic()
    }
  } catch {
    _ => panic()
  }
  let portals : Array[@map.MiniMapPortal] = []
  match map_json {
    { "portal": Object(portal_obj), .. } =>
      for _, portal_json in portal_obj {
        match portal_json {
          {
            "x": Number(x, ..),
            "y": Number(y, ..),
            "tm": Number(tm, ..),
            "pt": Number(pt, ..),
            ..
          } =>
            portals.push(
              @map.MiniMapPortal::new(
                x.to_int(),
                y.to_int(),
                tm.to_int(),
                @map.MiniMapPortalType::from_int(pt.to_int()),
              ),
            )
          _ => panic()
        }
      }
    _ => panic()
  }
  @map.MiniMapRuntimeResource::load(mini_map_resource, portals)
}

///|
test "mini map ui renders portal marker from real map 100030000" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  setup_mini_map_ui_scene_with_data(
    100030000,
    "Henesys",
    "Victoria Road",
    Some(load_real_minimap_runtime_resource_100030000()),
  )
  @capture_app.snapshot(
    "src/test/mini_map_ui_test/__snapshot__/mini_map_ui_with_portal_marker.png",
  )
}
