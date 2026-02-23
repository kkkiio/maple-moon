///|
/// Trait for passive skills that can respond to combat events
pub(open) trait PassiveSkill {
  /// Get unique identifier for this passive skill
  id(Self) -> Int
  /// Called when an attack hits targets
  on_hit(Self, PassiveContext, @combat_system.HitEvent) -> Unit
}
