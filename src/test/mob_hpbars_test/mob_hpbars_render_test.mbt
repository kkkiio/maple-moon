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
async test "mob hpbar render snapshot" {
  defer @monster.clear_map_monsters()
  defer @monster.mob_hpbars_system(0.0)
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()

  @capture_app.init_app(
    @system.App::new()
    .with_canvas_width(160.0)
    .with_canvas_height(120.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(@monster.mob_hpbars_system, system_name="mob_hpbars_system"),
  )
  let camera_anchor = @entity.Entity::new()
  @camera.attach_entity(camera_anchor, @math.Vec2D(0.0, 0.0))
  @camera.set_follow_x(true)
  @camera.set_follow_y(true)
  @camera.camera_system(0.016)

  let map_mobs = @monster.MapMobs::new()
  map_mobs.add_mob(load_test_mob())
  @monster.set_mobs({
    map_mobs,
    physics: @physics.empty_physics(),
  })
  map_mobs.for_each_mob(fn(_, mob) {
    mob.update(@physics.empty_physics()) |> ignore
    @position.positions.set(
      mob.get_entity(),
      @position.Position(@math.Vec2D(90.0, 80.0)),
    )
  })

  @monster.enqueue_hp_event(1001, 75, 0)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }

  @capture_app.snapshot(
    "src/test/mob_hpbars_test/__snapshot__/mob_hpbar_default.png",
  )
}
