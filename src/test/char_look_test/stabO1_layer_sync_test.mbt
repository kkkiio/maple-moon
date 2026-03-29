///|
async test "stabO1 frame layering stays synchronized with animation frame" {
  let previous_world = @ecs.current_world()
  let world = @ecs.World::new()
  @ecs.set_current_world(world)
  defer (match previous_world {
    Some(previous) => @ecs.set_current_world(previous)
    None => @ecs.clear_current_world()
  })

  @capture_app.init_app(
    @app.App::new()
    .with_world(world)
    .with_viewport_width(220.0)
    .with_viewport_height(220.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(world) { @ms_animation.animation_system(world) },
      system_name="ms_animation_system",
    )
    .add_system(
      Update,
      fn(world) { @char_look.char_look_system(world) },
      system_name="char_look_system",
    ),
  )

  let host = @entity.Entity::new()
  defer host.destroy()
  @transform2d.set_xy(host, Vec2D(110.0, 110.0))

  let look = load_test_look(host)
  let weapon_item = load_weapon_item(1312001)
  look.add_equip(weapon_item, @slot.Id::WEAPON)
  look.set_facing_right(true)
  look.set_stance(@char_stance.StanceId::STABO1)
  look.play_animations()

  fn sprite_z(entity : @entity.Entity) -> Double {
    @transform.transforms().get(entity).map_or(0.0, fn(t) { t.translation.z })
  }
  let frame0_z : Map[@entity.Entity, Double] = Map::new()
  for child in @entity.Entity::get_children(host) {
    if @sprite.sprites().get(child) is Some(_) {
      frame0_z.set(child, sprite_z(child))
    }
  }

  let mut ticks = 0
  while look.get_frame() < 1 && ticks < 60 {
    @time.set_delta(0.016)
    @capture_app.run_loop(0.016)
    ticks = ticks + 1
  }
  inspect(look.get_frame(), content="1")
  let mut changed_layer_count = 0
  for child in @entity.Entity::get_children(host) {
    if @sprite.sprites().get(child) is Some(_) {
      if frame0_z.get(child) is Some(before_z) {
        if before_z != sprite_z(child) {
          changed_layer_count = changed_layer_count + 1
        }
      }
    }
  }
  assert_true(changed_layer_count > 0)
}
