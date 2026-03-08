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
    @system.App::new()
    .with_viewport_width(220.0)
    .with_viewport_height(160.0)
    .add_plugin(@plugins.default_plugin),
  )

  let camera_anchor = @entity.Entity::new()
  @camera.attach_entity(camera_anchor, @math.Vec2D(0.0, 0.0))
  @camera.set_follow_x(true)
  @camera.set_follow_y(true)
  @camera.camera_system(0.016)

  let background = @entity.Entity::new()
  @position.positions.set(background, @position.Position(@math.Vec2D(0.0, 0.0)))
  let bg_rect = @sprite.ColorRect::new(
    @math.Vec2D(220.0, 160.0),
    "rgba(30, 60, 110, 1)",
  )
  @sprite.sprites.set(
    background,
    @sprite.Sprite::from_color_rect(bg_rect, @graphics.BACKGROUND_ZINDEX),
  )

  let mob = load_test_mob()
  mob.update(@physics.empty_physics()) |> ignore
  @position.positions.set(
    mob.get_entity(),
    @position.Position(@math.Vec2D(110.0, 95.0)),
  )
  mob.show_effect(animation, 0, z, false)

  for _ in 0..<2 {
    @capture_app.run_loop(0.016)
  }
}

///|
async test "final attack hit effect with EFFECT_ZINDEX stays visible" {
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  let (animation, _resource_z) = load_final_attack_hit_animation()
  setup_effect_scene(animation, @graphics.EFFECT_ZINDEX)
  @capture_app.snapshot(
    "src/test/final_attack_effect_test/__snapshot__/final_attack_hit_z_effect_layer.png",
  )
}

///|
test "parse CharLevel hit from real skill asset with structured decoder" {
  let skill_json = @fs.read_file_to_string("assets/skill/500.img.json")
    |> @json.parse
  let skill_5001001 = match skill_json {
    { "skill": { "5001001": skill, .. }, .. } => skill
    _ => fail("missing skill 5001001 in assets/skill/500.img.json")
  }
  let _ = @combat_system.make_hit_effect(skill_5001001)
}
