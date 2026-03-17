///|
fn load_map_root_102000001() -> Json {
  let map_json = (@fs.read_file_to_string("assets/map/map1/102000001.img.json")
  |> @json.parse) catch {
    _ => panic()
  }
  map_json
}

///|
fn join_dir(root : String, path : String) -> String {
  let normalized_root = root.strip_suffix("/").unwrap_or(root)
  let normalized_path = path.strip_prefix("/").unwrap_or(path)
  "\{normalized_root}/\{normalized_path}"
}

///|
fn get_by_path(obj : Json, path : String) -> Json {
  if path.is_empty() {
    return obj
  }
  let parts = path.split("/")
  parts.fold(init=obj, fn(acc, part) {
    match acc {
      Object(map) => map.get(part.to_string()).unwrap_or(null)
      _ => null
    }
  })
}

///|
fn has_hash_image_ref(json : Json) -> Bool {
  match json {
    { "__i": String(path), .. } => path.contains("#")
    Object(obj) => {
      for _, v in obj {
        if has_hash_image_ref(v) {
          return true
        }
      }
      false
    }
    Array(arr) => arr.any(has_hash_image_ref)
    _ => false
  }
}

///|
fn load_local_node_json(root_dir : String, path : Array[String]) -> Json {
  guard path.length() > 0 else { panic() }
  let root_file = join_dir(root_dir, path[0] + ".json")
  let root_json = @json.parse(@fs.read_file_to_string(root_file)) catch {
    _ => panic()
  }
  let mut sub_path = ""
  for i = 1; i < path.length(); i = i + 1 {
    if i > 1 {
      sub_path += "/"
    }
    sub_path += path[i]
  }
  let value = get_by_path(root_json, sub_path)
  if has_hash_image_ref(value) {
    panic()
  }
  value
}

///|
fn load_map_physics_102000001(root : Json) -> @physics.Physics {
  let fh_res = match root {
    { "foothold": foothold, .. } =>
      @json.from_json(foothold) catch {
        _ => panic()
      }
    _ => panic()
  }
  @physics.Physics::from_resource(fh_res) catch {
    _ => panic()
  }
}

///|
fn load_map_runtime_102000001() -> (@physics.Physics, @map.MapInfo) {
  let root = load_map_root_102000001()
  let nx_map : @map.NxMap = @json.from_json(root) catch { _ => panic() }
  let physics = load_map_physics_102000001(root)

  let tilesets : Map[String, @map.NxTileSet] = {}
  for layer in nx_map.layers {
    match layer.info {
      Some({ tS }) if not(tilesets.contains(tS)) =>
        tilesets[tS] = @json.from_json(
          load_local_node_json("assets/map/tile", [tS + ".img"]),
        ) catch {
          _ => panic()
        }
      _ => ()
    }
  }

  let object_animation_sets : Map[
    String,
    Map[@map.ObjectAnimationPath, @resource.NxAnimation],
  ] = {}
  for layer in nx_map.layers {
    for obj in layer.obj {
      let key = @map.ObjectAnimationPath::from_obj(obj)
      let set_map = object_animation_sets.get_or_init(obj.oS, fn() { {} })
      if not(set_map.contains(key)) {
        let anim_node = load_local_node_json("assets/map/obj", [
          obj.oS + ".img",
          obj.l0,
          obj.l1,
          obj.l2,
        ])
        set_map[key] = @json.from_json(anim_node) catch { _ => panic() }
      }
    }
  }

  let background_animation_sets : Map[
    String,
    Map[@map.BackgroundAnimationPath, @resource.NxAnimation],
  ] = {}
  for background in nx_map.back.0 {
    if background.bS == "" {
      continue
    }
    let key = @map.BackgroundAnimationPath::from_nx(background)
    let set_map = background_animation_sets.get_or_init(background.bS, fn() {
      {}
    })
    if not(set_map.contains(key)) {
      let anim_node = load_local_node_json("assets/map/back", [
        background.bS + ".img",
        if background.ani {
          "ani"
        } else {
          "back"
        },
        background.no.to_string(),
      ])
      set_map[key] = @json.from_json(anim_node) catch { _ => panic() }
    }
  }

  let tiles_objs = @map.MapLayers::new(
    tilesets,
    object_animation_sets,
    nx_map.layers,
  )
  let backgrounds = @map.load_backgrounds(
    nx_map.back,
    background_animation_sets,
  )
  @map.set_tiles_objs(tiles_objs)
  @map.set_backgrounds(backgrounds)

  let map_info = @map.MapInfo::from_resource(
    root,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  @map.set_runtime_context(map_info, physics)
  (physics, map_info)
}

///|
fn npc_sprite_zindices() -> Array[Int] {
  let zs : Array[Int] = []
  for _, sprite in @sprite.sprites() {
    match @test_snapshots.DebugSprite(sprite).to_json() {
      {
        "draw": [
          "Animation",
          { "current": { "sprite_path": String(path), .. }, .. },
        ],
        ..
      } if path.contains("Npc/") => zs.push(sprite.zindex)
      _ => ()
    }
  }
  zs.sort()
  zs
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
  @position.positions().set(camera_anchor, @position.Position(position))
  @camera.attach_entity(camera_anchor, @math.Vec2D(0.0, 0.0))
  @camera.set_follow_x(true)
  @camera.set_follow_y(true)
  let (left, right, top, bottom) = normalize_camera_limits(
    map_info.get_walls().first().to_double(),
    map_info.get_walls().second().to_double(),
    map_info.get_borders().first().to_double(),
    map_info.get_borders().second().to_double(),
  )
  @camera.set_limits(left~, right~, top~, bottom~)
  @camera.camera_system(0.016)
}

///|
fn spawn_npc_from_json(map_npcs : @npc.MapNpcs, json : Json) -> Unit {
  let msg : @server_proto.NpcSpawnControllerMessage = @json.from_json(json) catch {
    _ => panic()
  }
  map_npcs.apply_spawn_npc_controller_message(msg)
}

///|
async fn setup_shop_scene_npcs() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(_world) { @logic_fps.logic_fps_system(@time.delta()) },
      system_name="logic_fps_system",
    )
    .add_system(
      Update,
      fn(_world) { @map.background_system(@time.delta()) },
      system_name="background_system",
    )
    .add_system(
      Update,
      fn(_world) { @map.tile_objects_system(@time.delta()) },
      system_name="tile_objects_system",
    )
    .add_system(
      Update,
      fn(_world) { @npc.map_npcs_system(@time.delta()) },
      system_name="map_npcs_system",
    )
    .add_system(
      Update,
      fn(_world) { @io_service.io_system(@time.delta()) },
      system_name="io_system",
    )
  @capture_app.init_app(app)

  let (physics, map_info) = load_map_runtime_102000001()
  setup_camera(
    @math.Vec2D(
      map_info.get_walls().first().to_double(),
      map_info.get_borders().first().to_double(),
    ),
    map_info,
  )
  let npc_loader = @resource.AsyncLoader::new(
    "test_npc",
    loader=@local_loader.LocalDirResourceLoader::new("assets/Npc"),
    base_url="/assets",
  )
  let string_loader = @resource.AsyncLoader::new(
    "test_string",
    loader=@local_loader.LocalDirResourceLoader::new("assets/String"),
    base_url="/assets",
  )
  let map_npcs = @npc.MapNpcs::new(fn(_args) {  }, npc_loader~, string_loader~)
  @npc.set_npcs({ map_npcs, physics })

  spawn_npc_from_json(map_npcs, {
    "mode": 1,
    "oid": 100001,
    "id": 1021000,
    "x": -298,
    "y": 138,
    "flip": true,
    "fh": 11,
  })
  spawn_npc_from_json(map_npcs, {
    "mode": 1,
    "oid": 100002,
    "id": 1021001,
    "x": -253,
    "y": 138,
    "flip": true,
    "fh": 11,
  })

  for _ in 0..<180 {
    @capture_app.run_loop(0.016)
    @async.sleep(0)
    if npc_sprite_zindices().length() >= 2 {
      break
    }
  }
}

///|
async test "shop scene npc render snapshot on map 102000001" {
  defer @map.clear_runtime_context()
  defer @npc.clear_map_npcs()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  setup_shop_scene_npcs()

  @capture_app.snapshot(
    "src/test/shop_scene_test/__snapshot__/shop_scene_map_102000001_npcs.png",
  )
  inspect(
    npc_sprite_zindices(),
    content=(
      #|[30005, 30005]
    ),
  )
}
