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
fn setup_camera(position : @math.Vec2, map_info : @map.MapInfo) -> Unit {
  let camera_anchor = @entity.Entity()
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
}

///|
fn spawn_npc_from_json(map_npcs : @npc.MapNpcs, json : Json) -> Unit {
  let msg : @server_proto.NpcSpawnControllerMessage = @json.from_json(json) catch {
    _ => abort("unexpected shop item type in test")
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
  let npc_id = @string.parse_int(life.id) catch {
    _ => abort("failed to parse life id in test: " + life.id)
  }
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
fn setup_shop_scene_npcs() -> @app.App raise {
  let (app, _world) = @capture_app.new_graphics_test_app()
  let app = app
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .with_fixed_hz(125U)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @ms_camera.camera_follow_system(world) },
      system_name="camera_follow_system",
    )
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
  @system.configure_display(800.0, 600.0, 1.0)

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
  assert_true(npc_lives.length() > 0)
  @map.set_tiled_map(
    @ecs.require_current_world(),
    scene_map.tiled_map,
    background_animations=scene_map.background_animations,
  )
  @map.set_runtime_context(scene_map.map_info, scene_map.physics)

  setup_camera(@math.Vec2(-500.0, 320.0), scene_map.map_info)

  let map_npcs = @npc.MapNpcs::new(fn(_args) {  }, fn() { false })
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

  app
}

///|
test "shop scene npc render snapshot on map 102000001" {
  defer @map.clear_runtime_context()
  defer @map.clear_tiled_map(@ecs.require_current_world())
  defer @npc.clear_map_npcs()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let app = setup_shop_scene_npcs()
  let capture = @capture_app.capture_after_frames(
    app,
    154,
    width=800,
    height=600,
    raw_delta=0.016,
  )

  debug_inspect(
    @entity.iter_entities().to_array().length(),
    content=(
      #|61
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/shop_scene/shop_scene_map_102000001_npcs.png",
    capture.png,
  )
}
