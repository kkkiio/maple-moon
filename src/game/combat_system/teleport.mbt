///|
fn teleport(
  character : @character.Character,
  physics : @physics.Physics,
) -> Unit {
  let phobj = character.get_phobj()
  teleport_phobj(phobj, character.is_facing_right(), physics)
}

///|
/// Teleport a physics object by fixed horizontal distance and ground probe.
///
/// This helper is used by both runtime skill logic and integration tests.
pub fn teleport_phobj(
  phobj : @physics.PhysicsObject,
  facing_right : Bool,
  physics : @physics.Physics,
) -> Unit {
  let dist = 150.0
  let dx = if facing_right { dist } else { -dist }
  let curr_x = phobj.get_x().to_double()
  let curr_y = phobj.get_y().to_double()
  let dest_x = curr_x + dx

  // We probe down from a slightly higher y-coordinate to allow teleporting up slopes
  let probe_start_y = curr_y - 50.0
  let fh_tree = physics.get_fht()

  // Find the highest foothold strictly below probe_start_y at dest_x
  let dest_fh_id = fh_tree.get_fhid_below(dest_x, probe_start_y)

  if dest_fh_id > 0 {
    let dest_ground_y = fh_tree.get_ground_below_by_id(dest_fh_id, dest_x)

    // Check if the destination ground is within an acceptable height difference from current Y
    let y_diff = (dest_ground_y - curr_y).abs()

    // Allow teleporting up/down a slope or small cliff (e.g. max 100px difference)
    if y_diff <= 100.0 {
      @log.debug("teleport success", data={
        "curr_x": curr_x,
        "curr_y": curr_y,
        "dest_x": dest_x,
        "dest_y": dest_ground_y,
        "dest_fh_id": dest_fh_id,
      })
      phobj.set_x(dest_x)
      phobj.set_y(dest_ground_y)
      // Keep foothold state consistent with the snapped destination.
      phobj.set_fhid(dest_fh_id)

      // Reset velocity to prevent sliding after teleport
      phobj.set_hspeed(0.0)
      phobj.set_vspeed(0.0)
    }
  }
}
