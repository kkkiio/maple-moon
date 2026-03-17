///|
/// Source of the hit event, used to prevent recursive triggering
pub(all) enum HitSource {
  /// Player-initiated attack (can trigger passives)
  UserInput
  /// Passive skill triggered attack (cannot trigger passives again)
  Passive(Int)
} derive(Show, ToJson)

///|
/// Event fired when an attack hits one or more targets
pub(all) struct HitEvent {
  attacker_oid : Int
  move_id : Int
  source : HitSource
  target_oids : Array[Int]
  result : @combat_proto.AttackResult
} derive(Show, ToJson)

///|
/// Get attacker's OID from hit event
pub fn HitEvent::attacker_oid(self : HitEvent) -> Int {
  self.attacker_oid
}

///|
/// Get move ID from hit event
pub fn HitEvent::move_id(self : HitEvent) -> Int {
  self.move_id
}

///|
/// Get hit source (UserInput or Passive)
pub fn HitEvent::source(self : HitEvent) -> HitSource {
  self.source
}

///|
/// Get target OIDs from hit event
pub fn HitEvent::target_oids(self : HitEvent) -> Array[Int] {
  self.target_oids
}

///|
/// Check if this hit event is from user input (not passive)
pub fn HitEvent::is_user_input(self : HitEvent) -> Bool {
  match self.source {
    UserInput => true
    Passive(_) => false
  }
}

///|
/// Global event bus for hit events, consumed by passive skill system.
pub let hit_event_bus : @event.Events[HitEvent] = @event.Events::new()

///|
fn init {
  hit_event_bus.register_to_world(@ecs.require_current_world())
}

///|
/// Push a hit event to the global event bus.
pub fn push_event(event : HitEvent) -> Unit {
  hit_event_bus.send(event)
}

///|
/// Check if the global event bus has buffered events in the current window.
pub fn is_empty() -> Bool {
  let reader : @event.EventReader[HitEvent] = @event.EventReader::new()
  hit_event_bus.read(reader).is_empty()
}

///|
/// Clear all buffered hit events.
pub fn clear_events() -> Unit {
  hit_event_bus.clear()
}
