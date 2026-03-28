///|
fn load_final_attack_hit_animation() -> (@resource.NxAnimation, Int) raise {
  let skill_json = @fs.read_file_to_string("assets/skill/110.img.json")
    |> @json.parse
  let hit0 = match skill_json {
    {
      "skill": { "1100002": { "hit": { "0": { "0": hit0, .. }, .. }, .. }, .. },
      ..
    } => hit0
    _ => fail("missing final attack hit animation in assets/skill/110.img.json")
  }
  let z = match hit0 {
    { "z": Number(z, ..), .. } => z.to_int()
    _ => 0
  }
  (@json.from_json(hit0), z)
}

///|
fn load_test_mob() -> @monster.Mob raise {
  let mob_json = @fs.read_file_to_string("assets/mob/0100101.img.json")
    |> @json.parse
  let nx_mob : @monster.NxMob = @json.from_json(mob_json)
  @monster.Mob::new(
    nx_mob,
    0,
    0,
    0,
    false,
    { x: 110, y: 95 },
    object_id=1001,
    monster_id=100101,
  )
}

///|
fn setup_effect_scene(animation : @resource.NxAnimation, z : Int) -> Unit raise {
  @capture_app.init_app(
    @app.App::new()
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
      FixedUpdate,
      fn(world) { @monster.map_monsters_fixed_system(world) },
      system_name="map_monsters_fixed_system",
    )
    .add_system(
      Update,
      fn(world) { @ms_animation.animation_system(world) },
      system_name="ms_animation_system",
    ),
  )

  let camera_anchor = @entity.Entity::new()
  @transform2d.set_xy(camera_anchor, @math.Vec2D(110.0, 80.0))
  @ms_camera.setup_camera_entity(camera_anchor, center=@math.Vec2D(110.0, 80.0))
  @ms_camera.set_follow_target(camera_anchor)
  @ms_camera.camera_follow_system(@ecs.require_current_world())

  let mob = load_test_mob()
  let map_mobs = @monster.MapMobs::new()
  map_mobs.add_mob(mob)
  @monster.set_mobs({ map_mobs, physics: @physics.empty_physics() })
  mob.show_effect(animation, 0, z, false)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "final attack hit effect with EFFECT_ZINDEX stays visible" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()
  let (animation, _resource_z) = load_final_attack_hit_animation()
  setup_effect_scene(animation, @graphics.EFFECT_ZINDEX)
  @capture_app.snapshot(
    "src/test/final_attack_effect_test/__snapshot__/final_attack_hit_z_effect_layer.png",
    img_description="Final attack hit effect rendered correctly on the z-effect layer.",
  )
}
