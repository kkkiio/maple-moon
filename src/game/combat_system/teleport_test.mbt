///|
fn init {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  try! @res.configure_packs([("base", "assets/base")])
}

///|
fn load_map_physics(map_id : Int) -> @physics.Physics raise {
  let prefix = map_id / 100000000
  let mx_address = "res://Map/Map\{prefix}/\{map_id}.img.mx.json"
  let (_, tiled_map) = @res.load_tiled_map_from_mx(mx_address)
  let foothold_tree = @map.from_tiled_foothold_tree(tiled_map)
  @physics.Physics::from_resource(foothold_tree)
}

///|
fn make_physics_object(x : Int, y : Int, fh_id : Int) -> @physics.PhysicsObject {
  let phobj = PhysicsObject(on_pos_change=fn(_) {  })
  phobj.set_x(x.to_double())
  phobj.set_y(y.to_double())
  phobj.set_fhid(fh_id)
  phobj.set_hspeed(0.0)
  phobj.set_vspeed(0.0)
  phobj
}

///|
fn run_physics_frames(
  physics : @physics.Physics,
  phobj : @physics.PhysicsObject,
  frames : Int,
) -> Unit {
  for _ in 0..<frames {
    physics.move_object(phobj)
  }
}

///|
test "teleport on map 102030000 should stay on destination platform after frames" {
  let physics = load_map_physics(102030000)
  let phobj = make_physics_object(993, 105, 333)

  // The destination used in the regression report should resolve to foothold 176.
  let dest_fh_id = physics.get_fht().get_fhid_below(843.0, 55.0)
  assert_true(dest_fh_id == 176)

  // Facing left: 993 -> 843.
  teleport_phobj(phobj, false, physics)
  assert_true(phobj.get_x() == 843)
  assert_true(phobj.get_y() == 105)

  run_physics_frames(physics, phobj, 40)

  // Expected behavior: character should remain on destination platform.
  assert_true(phobj.get_y() == 105)
}

///|
test "teleport on map 102030000 should stay on slope destination platform after frames" {
  let physics = load_map_physics(102030000)
  let phobj = make_physics_object(2300, -124, 147)

  // Facing left: 2300 -> 2150.
  let dest_fh_id = physics.get_fht().get_fhid_below(2150.0, -174.0)
  assert_true(dest_fh_id == 144)
  let expected_ground = physics
    .get_fht()
    .get_ground_below_by_id(dest_fh_id, 2150.0)

  teleport_phobj(phobj, false, physics)
  run_physics_frames(physics, phobj, 40)

  // Expected behavior: remain on the slope foothold instead of falling.
  let y_diff = (phobj.get_y().to_double() - expected_ground).abs()
  assert_true(y_diff <= 1.0)
}

///|
using @physics {type PhysicsObject}
