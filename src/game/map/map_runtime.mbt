///|
let runtime_context_ref : Ref[(MapInfo, @physics.Physics)?] = Ref(None)

///|
/// Set current map runtime context for systems that need map info and physics.
pub fn set_runtime_context(
  map_info : MapInfo,
  physics : @physics.Physics,
) -> Unit {
  runtime_context_ref.val = Some((map_info, physics))
}

///|
/// Get current map runtime context.
pub fn get_runtime_context() -> (MapInfo, @physics.Physics)? {
  runtime_context_ref.val
}

///|
/// Clear current map runtime context.
pub fn clear_runtime_context() -> Unit {
  runtime_context_ref.val = None
  clear_portals()
}
