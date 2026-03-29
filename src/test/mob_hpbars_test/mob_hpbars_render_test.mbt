///|
fn load_test_mob() -> @monster.Mob raise {
  let mob_json = @fs.read_file_to_string("assets/mob/0100101.img.json")
    |> @json.parse
  let nx_mob : @monster.NxMob = @json.from_json(mob_json)
  let mob = @monster.Mob::new(
    nx_mob,
    0,
    0,
    0,
    false,
    @struct.Point::new(100, 95),
    object_id=1001,
    monster_id=100101,
  )
  mob
}

///|
fn attach_visible_mob_sprite(entity : @entity.Entity) -> Unit {
  let stand = @ms_animation.Animation::single_frame(
    "/assets/mob/0100101.img_stand.png",
    @math.Vec2D(35.0, 34.0),
    pivot=@math.Vec2D(16.0, 34.0),
  )
  @sprite.sprites().set(entity, @ms_animation.sprite_from_animation(stand, 0))
}

///|
async test "mob hpbar render snapshot" {
  defer @monster.clear_map_monsters()
  defer @monster.mob_hpbars_system(@ecs.require_current_world())
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let app = @app.App::new()
    .with_viewport_width(160.0)
    .with_viewport_height(120.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @monster.mob_hpbars_system(world) },
      system_name="mob_hpbars_system",
    )
  @capture_app.init_app(app)
  let mob_pos = @math.Vec2D(80.0, 86.0)
  let camera_center = @math.Vec2D(80.0, 62.0)
  let camera_anchor = @entity.Entity::new()
  @ms_camera.setup_camera_entity(camera_anchor, center=camera_center)
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())

  let map_mobs = @monster.MapMobs::new()
  map_mobs.add_mob(load_test_mob())
  @monster.set_mobs({ map_mobs, physics: @physics.empty_physics() })
  map_mobs.for_each_mob(fn(_, mob) {
    mob.update(@physics.empty_physics()) |> ignore
    @transform2d.set_xy(mob.get_entity(), mob_pos)
    attach_visible_mob_sprite(mob.get_entity())
  })

  @monster.enqueue_hp_event(1001, 75, 0)

  for _ in 0..<3 {
    @capture_app.run_loop(0.016)
  }

  @capture_app.snapshot(
    "src/test/mob_hpbars_test/__snapshot__/mob_hpbar_default.png",
    visual_desc="A mob is visible and its HP bar is rendered above the mob, horizontally centered.",
  )
}
