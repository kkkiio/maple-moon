///|
async fn load_final_attack_hit_animation() -> (@graphics.EffectAnimation, Int) {
  let skill_json = @fs.read_file_to_string("assets/skill/110.img.json")
    |> @json.parse
  let hit_node = match skill_json {
    { "skill": { "1100002": { "hit": { "0": hit0, .. }, .. }, .. }, .. } => hit0
    _ => fail("missing final attack hit animation in assets/skill/110.img.json")
  }
  let mx_animation_ref = match hit_node {
    { "mx_animation": String(path), .. } => path
    _ => fail("missing mx_animation for final attack hit effect")
  }
  let z = match hit_node {
    { "z": Number(z, ..), .. } => z.to_int()
    _ => 0
  }
  let skill_loader = @resource.require_async_loader("skill")
  let base_path = skill_loader.resolve_json_path("110.img.json")
  let resolved = @resource.resolve_ref(base_path, mx_animation_ref)
  let animation_loader = @resource.AnimationLoader::new(skill_loader)
  let loaded = animation_loader.load(resolved)
  let clip = loaded.clip("main")
  (
    {
      animation: @ms_animation.from_selene_clip(clip, loop_=false),
      duration_ms: clip.duration_ms,
    },
    z,
  )
}

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
async fn setup_effect_scene(
  world : @ecs.World,
  animation : @graphics.EffectAnimation,
  z : Int,
) -> Unit {
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
  mob.show_effect(animation, 1, z, false)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
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
  let (animation, _resource_z) = load_final_attack_hit_animation()
  setup_effect_scene(world, animation, @graphics.EFFECT_ZINDEX)
  @capture_app.snapshot(
    "src/test/final_attack_effect_test/__snapshot__/final_attack_hit_z_effect_layer.png",
    visual_desc="Final attack hit effect rendered correctly on the z-effect layer.",
  )
}
