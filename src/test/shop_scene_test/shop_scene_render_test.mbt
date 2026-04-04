///|
struct FlatJsonFileLoader {
  root : String
}

///|
pub fn FlatJsonFileLoader::new(root : String) -> FlatJsonFileLoader {
  { root, }
}

///|
pub impl @resource.AsyncResourceLoader for FlatJsonFileLoader with load_data(
  self,
  path,
) -> Json {
  let root = self.root.strip_suffix("/").unwrap_or(self.root)
  let raw_rel = path
    .to_string()
    .strip_prefix("/")
    .unwrap_or(path.to_string())
    .to_string()
  let rel = normalize_mapx_test_path(raw_rel)
  let full_path = "\{root}/\{rel}"
  (@fs.read_file_to_string(full_path) |> @json.parse) catch {
    _ => null
  }
}

///|
fn normalize_mapx_test_path(path : String) -> String {
  if path.has_prefix("Map/") {
    return path
  }
  if path.length() >= 6 && path.has_prefix("Map") && path.contains(".img/") {
    return "Map/\{path}"
  }
  path
}

///|
fn setup_resource_loaders() -> Unit {
  @resource.register_async_loader(
    "mapx",
    @resource.AsyncLoader::new(
      "test_mapx",
      loader=FlatJsonFileLoader::new("assets/map"),
    ),
  )
  @resource.register_async_loader(
    "npc",
    @resource.AsyncLoader::new(
      "test_npc",
      loader=FlatJsonFileLoader::new("assets"),
    ),
  )
  @resource.register_async_loader(
    "string",
    @resource.AsyncLoader::new(
      "test_string",
      loader=@local_loader.LocalDirResourceLoader::new("assets/String"),
    ),
  )
}

///|
fn normalize_camera_limits(
  left : Double,
  right : Double,
  top : Double,
  bottom : Double,
) -> (Double, Double, Double, Double) {
  let viewport_size = @system.get_viewport_size()
  let viewport_width = viewport_size.0
  let viewport_height = viewport_size.1
  let right = if right - left < viewport_width {
    left + viewport_width
  } else {
    right
  }
  let top = if bottom - top < viewport_height {
    bottom - viewport_height
  } else {
    top
  }
  (left, right, top, bottom)
}

///|
fn setup_camera(position : @math.Vec2D, map_info : @map.MapInfo) -> Unit {
  let camera_anchor = @entity.Entity::new()
  @transform2d.set_xy(camera_anchor, position)
  @ms_camera.setup_camera_entity(camera_anchor, center=position)
  @ms_camera.set_follow_target(camera_anchor)
  let (left, right, top, bottom) = normalize_camera_limits(
    map_info.get_walls().first().to_double(),
    map_info.get_walls().second().to_double(),
    map_info.get_borders().first().to_double(),
    map_info.get_borders().second().to_double(),
  )
  @ms_camera.set_limits(left, right, top, bottom)
  @ms_camera.camera_follow_system(@ecs.require_current_world())
}

///|
fn spawn_npc_from_json(map_npcs : @npc.MapNpcs, json : Json) -> Unit {
  let msg : @server_proto.NpcSpawnControllerMessage = @json.from_json(json) catch {
    _ => panic()
  }
  map_npcs.apply_spawn_npc_controller_message(msg)
}

///|
fn spawn_npc_from_life(
  map_npcs : @npc.MapNpcs,
  life : @map.NxLife,
  oid : Int,
  x : Int,
  y : Int,
) -> Unit {
  let npc_id = @string.parse_int(life.id) catch { _ => panic() }
  spawn_npc_from_json(map_npcs, {
    "mode": 1,
    "oid": oid,
    "id": npc_id,
    "x": x,
    "y": y,
    "flip": life.f != 0,
    "fh": life.fh,
  })
}

///|
async fn setup_shop_scene_npcs() -> Unit {
  setup_resource_loaders()
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .with_fixed_hz(125U)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @npc.map_npcs_pointer_system(world) },
      system_name="map_npcs_pointer_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @npc.map_npcs_fixed_system(world) },
      system_name="map_npcs_fixed_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
  @capture_app.init_app(app)

  let raw = @map.load_map_resources_by_id(102000001)
  let scene_map = @map.create_scene_map(
    raw,
    @map.Module::load().get_portals_animations(),
  )
  let npc_lives = []
  for life in scene_map.life_spawns {
    if life.type_ == "n" {
      npc_lives.push(life)
    }
  }
  guard npc_lives.length() > 0 else { panic() }
  @map.set_tiled_map(scene_map.tiled_map)
  @map.set_runtime_context(scene_map.map_info, scene_map.physics)

  setup_camera(@math.Vec2D(380.0, 460.0), scene_map.map_info)

  let map_npcs = @npc.MapNpcs::new(
    fn(_args) {  },
    fn() { false },
    npc_loader=@resource.require_async_loader("npc"),
    string_loader=@resource.require_async_loader("string"),
  )
  @npc.set_npcs({ map_npcs, physics: scene_map.physics })

  for idx in 0..<npc_lives.length() {
    spawn_npc_from_life(
      map_npcs,
      npc_lives[idx],
      100001 + idx,
      npc_lives[idx].x,
      npc_lives[idx].y,
    )
  }

  for _ in 0..<120 {
    @capture_app.run_loop(0.016)
  }
  let anchors = @npc.list_npc_anchors()
  if anchors.is_empty() {
    panic()
  }
  setup_camera(@math.Vec2D(-500.0, 320.0), scene_map.map_info)
  for _ in 0..<30 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "shop scene npc render snapshot on map 102000001" {
  defer @map.clear_runtime_context()
  defer @map.clear_tiled_map()
  defer @npc.clear_map_npcs()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  setup_shop_scene_npcs()
  for _ in 0..<4 {
    @capture_app.run_loop(0.016)
  }

  @capture_app.snapshot(
    "src/test/shop_scene_test/__snapshot__/shop_scene_map_102000001_npcs.png",
    visual_desc="Shop scene, two NPCs standing on the left, behind the counter.",
  )
}
