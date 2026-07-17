///|
test "walking mob advances its sprite animation" {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  defer @asset.set_io(fn(_path) { None })
  try! @res.configure_packs([
    ("base", "assets/base"),
    ("dlc-victoria", "assets/dlc-victoria"),
  ])
  defer @res.clear_mounts()
  defer clear_map_monsters()

  let world = @ecs.World()
  @ecs.set_current_world(world)
  let physics = @physics.empty_physics()
  let map_mobs = MapMobs::MapMobs()
  let mob = try! Mob::load(
    1001,
    100101,
    0,
    0,
    0,
    false,
    @struct.Point(110, 95),
    @random.Rand::new(),
  )
  map_mobs.add_mob(mob)
  set_mobs({ map_mobs, physics })
  map_monsters_render_system(world)
  let initial_frame = match @sprite.sprites().get(mob.get_entity()) {
    Some({ texture_atlas: Some(atlas), .. }) => atlas.index
    _ => fail("walking mob is missing its initial atlas frame")
  }
  @selene_animation.animation_player_system(0.13)
  @selene_animation.animation_apply_system(0.13)
  let advanced_frame = match @sprite.sprites().get(mob.get_entity()) {
    Some({ texture_atlas: Some(atlas), .. }) => atlas.index
    _ => fail("walking mob is missing its advanced atlas frame")
  }

  assert_true(initial_frame != advanced_frame)
}
