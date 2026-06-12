///|
fn load_json_from_file(path : String) -> Json raise {
  @fs.read_file_to_string(path) |> @json.parse
}

///|
fn load_real_mini_map_ui_json() -> Json raise {
  load_json_from_file("assets/UI/UIWindow2.img/MiniMap.json")
}

///|
fn load_real_map_helper_minimap_json() -> Json raise {
  load_json_from_file("assets/spritesheets/Map/MapHelper.img/minimap.json")
}

///|
fn make_test_runtime_resource_with_canvas(
  canvas_path : String,
  canvas_w : Int,
  canvas_h : Int,
  portals? : Array[@map.MiniMapPortal] = [],
) -> @map.MiniMapRuntimeResource raise {
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
  let mini_map_resource : @map.MiniMapResource = @json.from_json(mini_map_json)
  @map.MiniMapRuntimeResource::load(mini_map_resource, portals)
}

///|
fn setup_mini_map_ui_scene_with_data(
  map_id : Int,
  map_name : String,
  street_name : String,
  mini_map_resource : @map.MiniMapRuntimeResource?,
) -> @app.App raise {
  @mini_map_ui.set_minimap_json_for_test(load_real_mini_map_ui_json())
  @mini_map_ui.set_map_helper_minimap_json_for_test(
    load_real_map_helper_minimap_json(),
  )
  @mini_map_ui.clear_current_map()
  let app = @app.App()
    .with_viewport_width(420.0)
    .with_viewport_height(240.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(Update, fn(world) { @mini_map_ui.mini_map_ui_system(world) })
  @mini_map_ui.set_current_map(map_id, map_name, street_name, mini_map_resource)
  app.run_frames(300, raw_delta=0.016)
  app
}

///|
test "mini map ui renders normal frame" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let app = setup_mini_map_ui_scene_with_data(
    120010000,
    "Nautilus",
    "120010000",
    Some(
      make_test_runtime_resource_with_canvas(
        "assets/images/Map/30691.png", 269, 49,
      ),
    ),
  )
  @capture_app.ensure_webgpu_capture_runtime(420.0, 240.0)
  let captures = app.run_frames_capture(1, raw_delta=0.016)
  @capture_app.snapshot(
    "src/tests/mini_map_ui_test/__snapshot__/mini_map_ui_normal.png",
    captures[captures.length() - 1].png,
    visual_desc="Mini map UI is displayed showing the map layout, player position, and other standard elements.",
  )
}

///|
fn load_real_minimap_runtime_resource_100030000() -> @map.MiniMapRuntimeResource raise {
  let mx_path = ["Map", "Map1", "100030000.img.mx.json"]
  let (_, tiled_map) = @resource.load_tiled_map_from_mx(mx_path)
  let mini_opt = @map.from_tiled_mini_map_resource(tiled_map) catch {
    _ => None
  }
  let mini_map_resource = match mini_opt {
    Some(m) => m
    None => fail("miniMap not found in map 100030000")
  }
  let portals : Array[@map.MiniMapPortal] = []
  match tiled_map.object_layer("portal") {
    Some(layer) =>
      for obj in layer.objects {
        let x = obj.x.to_int()
        let y = obj.y.to_int()
        let tm = match obj.property("tm") {
          Some(@tiled.TiledPropertyValue::Int(v)) => v
          _ => 0
        }
        let pt = match obj.property("pt") {
          Some(@tiled.TiledPropertyValue::Int(v)) => v
          _ => 0
        }
        portals.push(@map.MiniMapPortal::new(x, y, tm, @map.MiniMapPortalType::from_int(pt)))
      }
    None => fail("portal layer not found in map 100030000")
  }
  @map.MiniMapRuntimeResource::load(mini_map_resource, portals)
}

///|
test "mini map ui renders portal marker from real map 100030000" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let app = setup_mini_map_ui_scene_with_data(
    100030000,
    "Henesys",
    "Victoria Road",
    Some(load_real_minimap_runtime_resource_100030000()),
  )
  @capture_app.ensure_webgpu_capture_runtime(420.0, 240.0)
  let captures = app.run_frames_capture(1, raw_delta=0.016)
  @capture_app.snapshot(
    "src/tests/mini_map_ui_test/__snapshot__/mini_map_ui_with_portal_marker.png",
    captures[captures.length() - 1].png,
    visual_desc="Mini map UI is displayed with portal markers visible on the map.",
  )
}
