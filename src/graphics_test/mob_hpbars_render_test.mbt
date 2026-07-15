///|
fn mob_hpbars_load_test_mob() -> @monster.Mob {
  @monster.Mob::load(
    1001,
    100101,
    0,
    0,
    0,
    false,
    @struct.Point(100, 95),
    @random.Rand::new(),
  )
}

///|
fn attach_visible_mob_sprite(entity : @entity.Entity) -> Unit {
  let stand = @ms_animation.Animation::single_frame(
    "assets/mob/0100101.img/animations/stand.png",
    @math.Vec2(35.0, 34.0),
    pivot=@math.Vec2(16.0, 34.0),
  )
  @sprite.sprites().set(entity, @ms_animation.sprite_from_animation(stand, 0))
}

///|
test "mob hpbar render snapshot" {
  defer @monster.clear_map_monsters()
  defer @monster.mob_hpbars_system(@ecs.require_current_world())
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let (app, _world) = @capture_app.new_graphics_test_app()
  let app = app
    .with_viewport_width(160.0)
    .with_viewport_height(120.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @monster.mob_hpbars_system(world) },
      system_name="mob_hpbars_system",
    )
    .add_system(
      Update,
      fn(world) { @ms_camera.camera_follow_system(world) },
      system_name="camera_follow_system",
    )
  @system.configure_display(160.0, 120.0, 1.0)
  let mob_pos = @math.Vec2(80.0, 86.0)
  let camera_center = @math.Vec2(80.0, 62.0)
  let camera_anchor = @entity.Entity()
  @ms_camera.setup_camera_entity(camera_anchor, center=camera_center)
  @ms_camera.set_follow_target(camera_anchor)

  let map_mobs = @monster.MapMobs()
  let mob = mob_hpbars_load_test_mob()
  map_mobs.add_mob(mob)
  @monster.set_mobs({ map_mobs, physics: @physics.empty_physics() })
  map_mobs.for_each_mob(fn(_, mob) {
    mob.update(@physics.empty_physics()) |> ignore
    @transform2d.set_xy(mob.get_entity(), mob_pos)
    attach_visible_mob_sprite(mob.get_entity())
  })

  @monster.enqueue_hp_event(1001, 75, 0)

  let capture = @capture_app.capture_after_frames(
    app,
    3,
    width=160,
    height=120,
    raw_delta=0.016,
  )

  debug_inspect(
    (
      mob.get_oid(),
      @transform2d.get_xy(mob.get_entity()),
      render_draw_state(capture),
    ),
    content=(
      #|(
      #|  1001,
      #|  Some(Vec2(80, 86)),
      #|  [
      #|    {
      #|      layer: "world",
      #|      kind: "Image",
      #|      texture_path: Some("assets/mob/0100101.img/animations/stand.png"),
      #|      source_rect: Some({ x: 0, y: 0, width: 35, height: 34 }),
      #|      destination_rect: Some({ x: 80, y: 84, width: 35, height: 34 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 59, y: 20, width: 50, height: 10 }),
      #|      color: Some({ r: 0, g: 0, b: 0, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 60, y: 21, width: 48, height: 1 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 60, y: 28, width: 48, height: 1 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 60, y: 22, width: 1, height: 6 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 107, y: 22, width: 1, height: 6 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 62, y: 23, width: 33, height: 3 }),
      #|      color: Some({ r: 0, g: 255, b: 0, a: 1 }),
      #|    },
      #|    {
      #|      layer: "world",
      #|      kind: "Rect",
      #|      texture_path: None,
      #|      source_rect: None,
      #|      destination_rect: Some({ x: 62, y: 26, width: 33, height: 1 }),
      #|      color: Some({ r: 0, g: 128, b: 0, a: 1 }),
      #|    },
      #|  ],
      #|)
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/mob_hpbars/mob_hpbar_default.png",
    capture.png,
  )
}
