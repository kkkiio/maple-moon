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
/// Global event queue for hit events, consumed by passive skill system
let hit_event_queue : Array[HitEvent] = Array::new()

///|
let hit_event_readers : Map[Int, Int] = {}

///|
let next_reader_id : Ref[Int] = Ref::new(1)

///|
/// Push a hit event to the global queue
pub fn push_event(event : HitEvent) -> Unit {
  hit_event_queue.push(event)
}

///|
/// Register a reader cursor for hit events.
/// New reader starts at current queue tail (will only read future events).
pub fn register_reader() -> Int {
  let reader_id = next_reader_id.val
  next_reader_id.val += 1
  hit_event_readers.set(reader_id, hit_event_queue.length())
  reader_id
}

///|
/// Unregister a reader cursor.
pub fn unregister_reader(reader_id : Int) -> Unit {
  ignore(hit_event_readers.remove(reader_id))
}

///|
/// Read all unread hit events for a reader and advance its cursor.
pub fn read_new_events(reader_id : Int) -> Array[HitEvent] {
  guard hit_event_readers.get(reader_id) is Some(cursor) else { return [] }
  let events = Array::new()
  let queue_len = hit_event_queue.length()
  for i in cursor..<queue_len {
    events.push(hit_event_queue[i])
  }
  hit_event_readers.set(reader_id, queue_len)
  events
}

///|
/// Garbage-collect hit events that all readers have consumed.
pub fn gc_consumed_events() -> Unit {
  if hit_event_readers.is_empty() {
    hit_event_queue.clear()
    return
  }
  let mut min_cursor = hit_event_queue.length()
  for _, cursor in hit_event_readers {
    if cursor < min_cursor {
      min_cursor = cursor
    }
  }
  guard min_cursor > 0 else { return }

  let retained = Array::new()
  for i in min_cursor..<hit_event_queue.length() {
    retained.push(hit_event_queue[i])
  }
  hit_event_queue.clear()
  for event in retained {
    hit_event_queue.push(event)
  }

  let reader_ids = hit_event_readers.keys().to_array()
  for reader_id in reader_ids {
    guard hit_event_readers.get(reader_id) is Some(cursor) else { continue }
    hit_event_readers.set(reader_id, cursor - min_cursor)
  }
}

///|
/// Check if the global event queue is empty
pub fn is_empty() -> Bool {
  hit_event_queue.is_empty()
}

///|
/// Clear all events from the global queue
pub fn clear_events() -> Unit {
  hit_event_queue.clear()
  let reader_ids = hit_event_readers.keys().to_array()
  for reader_id in reader_ids {
    hit_event_readers.set(reader_id, 0)
  }
}
