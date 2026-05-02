///|
async fn load_test_mob() -> @monster.Mob {
  @monster.Mob::load(
    1001,
    100101,
    0,
    0,
    0,
    false,
    { x: 110, y: 95 },
    @random.Rand::new(),
  )
}

///|
async test "final attack hit effect with EFFECT_ZINDEX stays visible" {
  @local_loader.install_resource_env_for_test()
  let previous_world = @ecs.current_world()
  let world = @ecs.World::new()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let data = @skill.SkillData::load(1100002)
  let skill_loader = @resource.require_async_loader("skill")
  let skill_base_path = "/assets/skill/110.img.json"
  let hit_effect = @combat_system.make_hit_effect(
    data.src,
    skill_loader,
    skill_base_path,
  )

  let user : @combat_proto.AttackUser = {
    skill_level: 0,
    level: 0,
    second_weapon: false,
    flip: false,
  }

  @capture_app.init_app(
    @app.App::new()
    .with_world(world)
    .with_viewport_width(220.0)
    .with_viewport_height(160.0)
    .with_fixed_hz(125U)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @monster.map_monsters_render_system(world) },
      system_name="map_monsters_render_system",
    )
    .add_system(
      Update,
      fn(world) { @ms_camera.camera_follow_system(world) },
      system_name="camera_follow_system",
    ),
  )

  let camera_anchor = @entity.Entity::new()
  @transform2d.set_xy(camera_anchor, @math.Vec2(110.0, 80.0))
  @ms_camera.setup_camera_entity(camera_anchor, center=@math.Vec2(110.0, 80.0))
  @ms_camera.set_follow_target(camera_anchor)

  let mob = load_test_mob()
  let map_mobs = @monster.MapMobs::new()
  map_mobs.add_mob(mob)
  @monster.set_mobs({ map_mobs, physics: @physics.empty_physics() })

  hit_effect(user, mob)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }

  @capture_app.snapshot(
    "src/test/final_attack_effect_test/__snapshot__/final_attack_hit_z_effect_layer.png",
    visual_desc="A attack hit effect rendered on top of the monster",
  )
}
