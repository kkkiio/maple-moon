///|
async fn setup_tiled_background_scene_101010102() -> Unit {
  @local_loader.install_resource_env_for_test()
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(600.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @map.tiled_background_motion_system(world) },
      system_name="tiled_background_motion_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
  @capture_app.init_app(app)
  let raw = @map.load_map_resources_by_id(101010102)
  @map.set_tiled_map(raw.tiled_map)
  let camera_anchor = @entity.Entity::new()
  @transform2d.set_xy(camera_anchor, @math.Vec2D(0.0, 0.0))
  @ms_camera.setup_camera_entity(
    camera_anchor,
    center=@transform2d.get_xy(camera_anchor).unwrap_or(@math.Vec2D::zero()),
  )
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())
}

///|
fn min_sprite_alpha() -> Double {
  let mut found = false
  let mut min_alpha = 1.0
  for _, sprite in @sprite.sprites() {
    found = true
    if sprite.color.a < min_alpha {
      min_alpha = sprite.color.a
    }
  }
  if !found {
    panic()
  }
  min_alpha
}

///|
fn visible_sprite_count() -> Int {
  let mut count = 0
  for entity, _ in @sprite.sprites() {
    if @visibility.is_visible(entity) {
      count += 1
    }
  }
  count
}

///|
async test "map 101010102 tiled background render snapshot" {
  defer @map.clear_tiled_map()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  setup_tiled_background_scene_101010102()
  for _ in 0..<80 {
    @capture_app.run_loop(0.016)
  }

  let start_alpha = min_sprite_alpha()
  assert_true(start_alpha >= 0.0)
  assert_true(visible_sprite_count() > 0)
  @capture_app.snapshot(
    "src/test/map_background_test/__snapshot__/map_101010102_bg_alpha_start.png",
    visual_desc="Large green tree trunks and vines fill most of the screen, with lighter tree layers visible in the far background.",
  )

  for _ in 0..<12 {
    @capture_app.run_loop(0.016)
  }

  let after_motion_alpha = min_sprite_alpha()
  assert_true(after_motion_alpha >= 0.0)
  assert_true(visible_sprite_count() > 0)
  @capture_app.snapshot(
    "src/test/map_background_test/__snapshot__/map_101010102_bg_alpha_mid.png",
    visual_desc="Overlapping foreground and background tree layers create a dense forest view, with thick trunks crossing the center of the screen.",
  )
}
