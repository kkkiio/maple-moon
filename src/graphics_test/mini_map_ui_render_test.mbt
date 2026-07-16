///|
fn load_json_from_file(path : String) -> Json raise {
  @res.load_json(path)
}

///|
fn load_real_mini_map_ui_json() -> Json raise {
  load_json_from_file("res://UI/UIWindow2.img/MiniMap.json")
}

///|
fn load_real_map_helper_minimap_json() -> Json raise {
  load_json_from_file("res://Map/MapHelper.img/minimap.json")
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
struct MiniMapRenderState {
  canvas_path : String
  canvas_width : Int
  canvas_height : Int
  portals : Array[(Int, Int, Int, @map.MiniMapPortalType)]
} derive(Debug)

///|
fn mini_map_render_state(
  resource : @map.MiniMapRuntimeResource,
) -> MiniMapRenderState {
  {
    canvas_path: resource.canvas.path,
    canvas_width: resource.canvas.width,
    canvas_height: resource.canvas.height,
    portals: resource.portals.map(fn(portal) {
      (portal.x, portal.y, portal.tm, portal.pt)
    }),
  }
}

///|
fn setup_mini_map_ui_scene_with_data(
  app : @app.App,
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
  let app = app
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
  @capture_app.ensure_native_context(width=420, height=240)
  let (app, _world) = @capture_app.new_graphics_test_app()
  let resource = make_test_runtime_resource_with_canvas(
    "res://Map/MapHelper.img/30691.png", 269, 49,
  )
  let app = setup_mini_map_ui_scene_with_data(
    app,
    120010000,
    "Nautilus",
    "120010000",
    Some(resource),
  )
  let capture = @capture_app.capture_after_frames(
    app,
    1,
    width=420,
    height=240,
    raw_delta=0.016,
  )
  debug_inspect(
    mini_map_render_state(resource),
    content=(
      #|{
      #|  canvas_path: "res://Map/MapHelper.img/30691.png",
      #|  canvas_width: 269,
      #|  canvas_height: 49,
      #|  portals: [],
      #|}
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/mini_map_ui/mini_map_ui_normal.png",
    capture.png,
  )
}

///|
fn load_real_minimap_runtime_resource_100030000() -> @map.MiniMapRuntimeResource raise {
  let mx_path = "res://Map/Map1/100030000.img.mx.json"
  let (_, tiled_map) = @res.load_tiled_map_from_mx(mx_path)
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
        portals.push(
          MiniMapPortal(x, y, tm, @map.MiniMapPortalType::from_int(pt)),
        )
      }
    None => fail("portal layer not found in map 100030000")
  }
  @map.MiniMapRuntimeResource::load(mini_map_resource, portals)
}

///|
test "mini map ui renders portal marker from real map 100030000" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  @capture_app.ensure_native_context(width=420, height=240)
  let (app, _world) = @capture_app.new_graphics_test_app()
  let resource = load_real_minimap_runtime_resource_100030000()
  let app = setup_mini_map_ui_scene_with_data(
    app,
    100030000,
    "Henesys",
    "Victoria Road",
    Some(resource),
  )
  let capture = @capture_app.capture_after_frames(
    app,
    1,
    width=420,
    height=240,
    raw_delta=0.016,
  )
  debug_inspect(
    mini_map_render_state(resource),
    content=(
      #|{
      #|  canvas_path: "assets/base/Map/tiles/../images/30864.png",
      #|  canvas_width: 243,
      #|  canvas_height: 155,
      #|  portals: [
      #|    (-4142, -2, 999999999, SPAWN),
      #|    (-1380, -1064, 999999999, SPAWN),
      #|    (-1296, -946, 999999999, SPAWN),
      #|    (-969, -407, 999999999, SPAWN),
      #|    (-1682, -163, 999999999, SPAWN),
      #|    (-4209, 133, 999999999, SPAWN),
      #|    (-4054, -595, 999999999, SPAWN),
      #|    (-3673, -229, 999999999, SPAWN),
      #|    (-3314, -1193, 999999999, SPAWN),
      #|    (-2453, -1427, 999999999, SPAWN),
      #|    (-4301, -1318, 999999999, SPAWN),
      #|    (-1861, -646, 999999999, SPAWN),
      #|    (-1105, 160, 120010000, REGULAR),
      #|    (-4428, -1286, 999999999, SCRIPTED),
      #|    (-3368, -1463, 100030001, HIDDEN),
      #|    (-1237, -870, 100030000, INVISIBLE),
      #|    (-2986, 273, 100030000, INVISIBLE),
      #|    (-991, -856, 100040000, REGULAR),
      #|    (-4370, 163, 100020000, REGULAR),
      #|  ],
      #|}
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/mini_map_ui/mini_map_ui_with_portal_marker.png",
    capture.png,
  )
}
