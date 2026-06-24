///|
fn setup_tiled_background_scene_101010102() -> @app.App raise {
  let app = @app.App()
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
  @ecs.set_current_world(app.world())
  @system.configure_display(800.0, 600.0, 1.0)
  let raw = @map.load_map_resources_by_id(101010102)
  @map.set_tiled_map(
    @ecs.require_current_world(),
    raw.tiled_map,
    background_animations=raw.background_animations,
  )
  let camera_anchor = @entity.Entity()
  @transform2d.set_xy(camera_anchor, @math.Vec2(0.0, 0.0))
  @ms_camera.setup_camera_entity(
    camera_anchor,
    center=@transform2d.get_xy(camera_anchor).unwrap_or(@math.Vec2::zero()),
  )
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())
  app
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
    abort("map background resource not set in test")
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
test "map 101010102 tween lighting alpha background start" {
  defer @map.clear_tiled_map(@ecs.require_current_world())
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let app = setup_tiled_background_scene_101010102()
  let capture = @capture_app.capture_after_frames(
    app,
    80,
    width=800,
    height=600,
    raw_delta=0.016,
  )

  let start_alpha = min_sprite_alpha()
  assert_true(start_alpha >= 0.0)
  assert_true(visible_sprite_count() > 0)
  debug_inspect(@entity.iter_entities().to_array().length(), content=(#|713
  ))
  @capture_app.snapshot(
    "src/tests/map_background_test/__snapshot__/map_101010102_bg_alpha_start.png",
    capture.png,
  )
}

///|
test "map 101010102 tween lighting alpha background mid" {
  defer @map.clear_tiled_map(@ecs.require_current_world())
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let app = setup_tiled_background_scene_101010102()
  let capture = @capture_app.capture_after_frames(
    app,
    158,
    width=800,
    height=600,
    raw_delta=0.016,
  )

  let after_motion_alpha = min_sprite_alpha()
  assert_true(after_motion_alpha >= 0.0)
  assert_true(visible_sprite_count() > 0)
  debug_inspect(@entity.iter_entities().to_array().length(), content=(#|713
  ))
  @capture_app.snapshot(
    "src/tests/map_background_test/__snapshot__/map_101010102_bg_alpha_mid.png",
    capture.png,
  )
}

///|
fn setup_tiled_background_scene_100000000() -> @app.App raise {
  let app = @app.App()
    .with_viewport_width(1366.0)
    .with_viewport_height(768.0)
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
  @ecs.set_current_world(app.world())
  @system.configure_display(1366.0, 768.0, 1.0)
  let raw = @map.load_map_resources_by_id(100000000)
  @map.set_tiled_map(
    @ecs.require_current_world(),
    raw.tiled_map,
    background_animations=raw.background_animations,
  )
  let camera_anchor = @entity.Entity()
  @transform2d.set_xy(camera_anchor, @math.Vec2(0.0, 0.0))
  @ms_camera.setup_camera_entity(
    camera_anchor,
    center=@transform2d.get_xy(camera_anchor).unwrap_or(@math.Vec2::zero()),
  )
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())
  app
}

///|
test "map 100000000 background" {
  defer @map.clear_tiled_map(@ecs.require_current_world())
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let app = setup_tiled_background_scene_100000000()
  let capture = @capture_app.capture_after_frames(
    app,
    5,
    width=1366,
    height=768,
    raw_delta=0.016,
  )

  assert_true(visible_sprite_count() > 0)
  let background_sprite_positions : Array[(Int, Int, Int, Int, Int, Int, Int)] = []
  for entity, sprite in @sprite.sprites() {
    guard sprite.custom_size is Some(size) else { continue }
    let width = size[@math.X].to_int()
    let height = size[@math.Y].to_int()
    guard (width == 1024 && height == 579) ||
      (width == 2493 && height == 340) ||
      (width == 315 && height == 268) ||
      (width == 1024 && height == 257) ||
      (width == 1024 && height == 294) else {
      continue
    }
    let global_translation = @transform.global_transforms()
      .get(entity)
      .map(fn(transform) { transform.translation() })
      .unwrap_or(@math.Vec3::zero())
    let global_pos = @math.Vec2(global_translation.x, global_translation.y)
    let viewport_pos = @ms_camera.world_to_viewport(global_pos)
    let global_z = @transform.global_transforms()
      .get(entity)
      .map(fn(transform) {
        transform.translation().z.round().to_int()
      })
      .unwrap_or(0)
    background_sprite_positions.push((
      width,
      height,
      global_pos[@math.X].round().to_int(),
      global_pos[@math.Y].round().to_int(),
      viewport_pos[@math.X].round().to_int(),
      viewport_pos[@math.Y].round().to_int(),
      global_z,
    ))
  }
  background_sprite_positions.sort_by(fn(lhs, rhs) {
    let lhs_key = lhs.0.compare(rhs.0)
    if lhs_key != 0 {
      return lhs_key
    }
    let lhs_height_key = lhs.1.compare(rhs.1)
    if lhs_height_key != 0 {
      return lhs_height_key
    }
    let lhs_x_key = lhs.4.compare(rhs.4)
    if lhs_x_key != 0 {
      return lhs_x_key
    }
    let lhs_y_key = lhs.5.compare(rhs.5)
    if lhs_y_key != 0 {
      return lhs_y_key
    }
    lhs.6.compare(rhs.6)
  })
  let camera_top_left = @ms_camera.current_camera_top_left()
  let draw_29100_commands : Array[(Int, Int, Int, Int, Int)] = []
  for item in capture.metadata.draw2d {
    guard item.texture_path is Some(texture_path) &&
      texture_path.contains("29100.png") &&
      item.destination_rect is Some(rect) else {
      continue
    }
    draw_29100_commands.push((
      rect.x.round().to_int(),
      rect.y.round().to_int(),
      rect.width.round().to_int(),
      rect.height.round().to_int(),
      item.depth.map(fn(depth) { depth.round().to_int() }).unwrap_or(0),
    ))
  }
  debug_inspect((
    @entity.iter_entities().to_array().length(),
    (
      camera_top_left[@math.X].round().to_int(),
      camera_top_left[@math.Y].round().to_int(),
    ),
    background_sprite_positions,
    draw_29100_commands,
  ), content=(
    #|(
    #|  1626,
    #|  (-683, -384),
    #|  [
    #|    (315, 268, -103, -231, 580, 153, 2006),
    #|    (1024, 257, -818, 214, -135, 598, 2008),
    #|    (1024, 257, 1230, 214, 1913, 598, 2012),
    #|    (1024, 294, 206, 177, 889, 561, 2010),
    #|    (1024, 294, 2254, 177, 2937, 561, 2014),
    #|    (1024, 579, -779, -202, -96, 182, 2002),
    #|    (1024, 579, 245, -202, 928, 182, 2002),
    #|    (1024, 579, 1269, -202, 1952, 182, 2002),
    #|    (1024, 579, 2293, -202, 2976, 182, 2002),
    #|    (1024, 579, 3317, -202, 4000, 182, 2002),
    #|    (2493, 340, -1071, 37, -388, 421, 2004),
    #|  ],
    #|  [(-388, 421, 2493, 340, 2004)],
    #|)

  ))
  @capture_app.snapshot(
    "src/tests/map_background_test/__snapshot__/map_100000000_bg.png",
    capture.png,
  )
}
