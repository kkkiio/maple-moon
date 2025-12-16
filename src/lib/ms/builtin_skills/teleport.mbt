///|
/// 传送技能.
/// MVP Implementation Note:
/// This is a simplified debug teleport that bypasses validity checks.
///
/// A proper production implementation should:
/// 1. Raycast Check (Wall Check):
///    - Cast a ray from (current_x, current_y) to (new_x, new_y).
///    - If it hits a wall (foothold with vertical component / wall property), stop there.
///
/// 2. Foothold Probe (Ground Check):
///    - At the target (new_x, new_y), cast a ray downwards (e.g. +100px).
///    - If a valid foothold is found, snap new_y to that foothold's y-level.
///    - If no foothold is found (void) or inside a wall, the teleport should fail.
///
/// 3. Map Bounds Check:
///    - Clamp new_x/new_y within the map boundaries.
pub fn teleport(character : @character.Character) -> Unit {
  let dist = 150.0
  let mut dx = 0.0

  // Horizontal movement
  if character.is_facing_right() {
    dx += dist
  } else {
    dx -= dist
  }
  let phobj = character.get_phobj()
  let new_x = phobj.get_x().to_double() + dx
  phobj.set_x(new_x)

  // Reset velocity to prevent sliding after teleport
  phobj.set_hspeed(0.0)
  phobj.set_vspeed(0.0)
}
