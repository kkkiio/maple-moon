///|
fn load_json_from_file(path : String) -> Json {
  (@fs.read_file_to_string(path) |> @json.parse) catch {
    _ => panic()
  }
}

///|
fn load_map_root_101010102() -> Json {
  load_json_from_file("assets/map/map1/101010102.img.json")
}

///|
async fn load_backgrounds_101010102() -> @map.Backgrounds {
  let root = load_map_root_101010102()
  let nx_map : @map.NxMap = @json.from_json(root) catch { _ => panic() }
  let background_loader = @resource.AsyncLoader::new(
    "test_background",
    loader=@local_loader.LocalDirResourceLoader::new("assets/map/back"),
    base_url="/assets",
  )
  let background_animation_sets : Map[
    String,
    Map[@map.BackgroundAnimationPath, @resource.NxAnimation],
  ] = {}
  for background in nx_map.back.0 {
    if background.bS == "" {
      continue
    }
    let path = @map.BackgroundAnimationPath::from_nx(background)
    let set_map = background_animation_sets.get_or_init(background.bS, fn() {
      {}
    })
    if not(set_map.contains(path)) {
      set_map[path] = @map.load_background_animation(
        background_loader,
        background.bS,
        path,
      )
    }
  }
  @map.load_backgrounds(nx_map.back, background_animation_sets)
}

///|
async fn setup_background_scene_101010102() -> Unit {
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
      fn(_world) { @io_service.io_system(@time.delta()) },
      system_name="io_system",
    )
  @capture_app.init_app(app)
  let backgrounds = load_backgrounds_101010102()
  @map.set_backgrounds(backgrounds)
  let camera_anchor = @entity.Entity::new()
  @position.positions().set(
    camera_anchor,
    @position.Position(@math.Vec2D(-760.0, -760.0)),
  )
  @camera.attach_entity(camera_anchor, @math.Vec2D(0.0, 0.0))
  @camera.set_follow_x(true)
  @camera.set_follow_y(true)
  @camera.camera_system(0.016)
}

///|
fn min_sprite_alpha() -> Double {
  let mut found = false
  let mut min_alpha = 1.0
  for _, sprite in @sprite.sprites() {
    found = true
    if sprite.alpha < min_alpha {
      min_alpha = sprite.alpha
    }
  }
  if not(found) {
    panic()
  }
  min_alpha
}

///|
fn visible_sprite_count() -> Int {
  let mut count = 0
  for _, sprite in @sprite.sprites() {
    if sprite.visible {
      count += 1
    }
  }
  count
}

///|
async test "map 101010102 background alpha animation snapshot" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  setup_background_scene_101010102()
  @capture_app.run_loop(0.016)

  let start_alpha = min_sprite_alpha()
  assert_true(start_alpha < 1.0)
  assert_true(visible_sprite_count() > 0)
  @capture_app.snapshot(
    "src/test/map_background_test/__snapshot__/map_101010102_bg_alpha_start.png",
    img_description="Map background rendered with initial alpha transparency.",
  )

  for _ in 0..<78 {
    @capture_app.run_loop(0.016)
  }

  let mid_alpha = min_sprite_alpha()
  assert_true(mid_alpha >= 0.0)
  assert_true(mid_alpha < start_alpha)
  @capture_app.snapshot(
    "src/test/map_background_test/__snapshot__/map_101010102_bg_alpha_mid.png",
    img_description="Map background rendered with mid-level alpha transparency.",
  )
}
