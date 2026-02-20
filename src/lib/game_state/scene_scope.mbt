///|
/// Scene-scoped cleanup hooks.
///
/// This module provides a tiny lifecycle hook mechanism that game modules can
/// use to clean up their own map-scoped objects when the game switches scenes.
///
/// The scene transition code should call `emit_scene_clear`, and modules should
/// register cleanup logic via `listen_scene_clear`.
pub(all) enum SceneClearReason {
  /// Leaving the in-game scene to character selection (or similar).
  LeaveToSelectCharacter
  /// Entering the game world from login/character selection.
  GameStart
  /// Switching maps while already in-game.
  ChangeMap
} derive(Eq, Show)

///|
/// A scene-clear listener.
///
/// Return `true` to keep the listener registered; return `false` to unregister.
pub type SceneClearListener = (SceneClearReason) -> Bool

///|
let scene_clear_listeners : Ref[Array[SceneClearListener]] = Ref::new(
  Array::new(),
)

///|
/// Register a scene-clear listener.
pub fn listen_scene_clear(listener : SceneClearListener) -> Unit {
  scene_clear_listeners.val.push(listener)
}

///|
/// Emit a scene-clear event.
pub fn emit_scene_clear(reason : SceneClearReason) -> Unit {
  scene_clear_listeners.val.retain(fn(listener) { listener(reason) })
}
