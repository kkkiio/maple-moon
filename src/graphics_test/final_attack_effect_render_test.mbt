///|
fn final_attack_load_test_mob() -> @monster.Mob raise {
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
test "final attack hit effect with EFFECT_ZINDEX stays visible" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let data = @skill.SkillData::load(1100002)
  let skill_base_path = "res://Skill/110.img.json"
  let hit_effect = @combat_system.make_hit_effect(data.src, skill_base_path)

  let user : @combat_proto.AttackUser = {
    skill_level: 0,
    level: 0,
    second_weapon: false,
    flip: false,
  }

  let app = @app.App()
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
    )

  let camera_anchor = @entity.Entity()
  @transform2d.set_xy(camera_anchor, @math.Vec2(110.0, 80.0))
  @ms_camera.setup_camera_entity(camera_anchor, center=@math.Vec2(110.0, 80.0))
  @ms_camera.set_follow_target(camera_anchor)

  let mob = final_attack_load_test_mob()
  let map_mobs = @monster.MapMobs()
  map_mobs.add_mob(mob)
  @monster.set_mobs({ map_mobs, physics: @physics.empty_physics() })

  hit_effect(user, mob)

  let capture = @capture_app.capture_after_frames(
    app,
    2,
    width=220,
    height=160,
    raw_delta=0.016,
  )

  let effect_children = @entity.Entity::get_children(mob.get_entity())
  debug_inspect(
    (
      mob.get_oid(),
      mob.get_position(),
      render_draw_state(
        capture,
        entity_ids=effect_children.map(fn(child) { child.id() }),
      ),
    ),
    content=(
      #|(
      #|  1001,
      #|  { x: 110, y: 95 },
      #|  [
      #|    {
      #|      layer: "world",
      #|      kind: "Image",
      #|      texture_path: Some("assets/base/Skill/110.img/animations/skill__1100002.png"),
      #|      source_rect: Some({ x: 175, y: 0, width: 167, height: 92 }),
      #|      destination_rect: Some({ x: 114, y: 61, width: 167, height: 92 }),
      #|      color: Some({ r: 255, g: 255, b: 255, a: 1 }),
      #|    },
      #|  ],
      #|)
    ),
  )
  @capture_app.snapshot(
    "src/graphics_test/__snapshot__/final_attack_effect/final_attack_hit_z_effect_layer.png",
    capture.png,
  )
}
