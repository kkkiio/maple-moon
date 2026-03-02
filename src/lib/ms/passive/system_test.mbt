///|
/// Test that passive_system consumes events from queue
/// Note: SwordFaFighterPassive will return early due to no player/combat,
/// but the events should still be consumed from queue
test "passive_system_consumes_events" {
  // Clear queue before test
  @combat_system.clear_events()

  // Push an event
  let event : @combat_system.HitEvent = {
    attacker_oid: 1,
    move_id: 100,
    source: @combat_system.HitSource::UserInput,
    target_oids: [101],
    result: @combat_proto.AttackResult::default(),
  }
  @combat_system.push_event(event)

  // Call passive_system - events should be consumed even though
  // SwordFaFighterPassive returns early (no player/combat)
  passive_system(0.016)

  // Event should be consumed from queue
  assert_true(@combat_system.is_empty())

  // Clean up
  @combat_system.clear_events()
}

///|
/// Mock passive skill that records on_hit calls
struct MockPassiveSkill {
  call_count : Ref[Int]
  last_event : Ref[@combat_system.HitEvent?]
}

///|
fn MockPassiveSkill::new() -> MockPassiveSkill {
  {
    call_count: Ref::new(0),
    last_event: Ref::new((None : @combat_system.HitEvent?)),
  }
}

///|
impl PassiveSkill for MockPassiveSkill with id(_self) -> Int {
  -999
}

///|
impl PassiveSkill for MockPassiveSkill with on_hit(
  self : MockPassiveSkill,
  _ctx : PassiveContext,
  event : @combat_system.HitEvent,
) -> Unit {
  self.call_count.val += 1
  self.last_event.val = Some(event)
}

///|
fn make_system_test_ctx() -> PassiveContext {
  PassiveContext::{
    randomizer: @random.Rand::new(),
    get_character_fn: fn(_oid) { None },
    get_skill_level_fn: fn(_attacker_oid, _skill_id) { 0 },
    get_skill_data_fn: fn(_skill_id) { None },
    trigger_extra_attack_fn: fn(_attacker_oid, _skill_id, _targets) {  },
  }
}

///|
/// Test that mock passive skill records on_hit calls correctly
test "mock_passive_skill_on_hit" {
  let mock = MockPassiveSkill::new()

  // Initially no calls
  assert_eq(mock.call_count.val, 0)
  assert_true(mock.last_event.val is None)

  // Verify mock id
  assert_eq(mock.id(), -999)

  // Test on_hit records the event (PassiveContext is now empty)
  let ctx = make_system_test_ctx()
  let event : @combat_system.HitEvent = {
    attacker_oid: 1,
    move_id: 100,
    source: @combat_system.HitSource::UserInput,
    target_oids: [101, 102],
    result: @combat_proto.AttackResult::default(),
  }
  mock.on_hit(ctx, event)

  // Verify on_hit was called and recorded the event
  assert_eq(mock.call_count.val, 1)
  assert_false(mock.last_event.val is None)
  assert_eq(mock.last_event.val.unwrap().move_id(), 100)

  // Clean up
  @combat_system.clear_events()
}

///|
/// Test that passive_system calls registered mock skill correct number of times
test "passive_system_calls_mock_skill" {
  // Clear queue before test
  @combat_system.clear_events()

  // Create and register mock skill
  let mock = MockPassiveSkill::new()
  register_passive_skill(mock)

  // Push 3 events to queue
  for i in 0..<3 {
    let event : @combat_system.HitEvent = {
      attacker_oid: 1,
      move_id: 100 + i,
      source: @combat_system.HitSource::UserInput,
      target_oids: [101 + i],
      result: @combat_proto.AttackResult::default(),
    }
    @combat_system.push_event(event)
  }

  // Verify mock has not been called yet
  assert_eq(mock.call_count.val, 0)

  // Call passive_system
  passive_system(0.016)

  // Verify mock's on_hit was called 3 times (once per event)
  assert_eq(mock.call_count.val, 3)

  // Verify last event was recorded
  assert_false(mock.last_event.val is None)
  assert_eq(mock.last_event.val.unwrap().move_id(), 102) // Last event's move_id

  // All events should be consumed
  assert_true(@combat_system.is_empty())

  // Clean up - push more events and call again to verify it still works
  for i in 0..<2 {
    let event : @combat_system.HitEvent = {
      attacker_oid: 2,
      move_id: 200 + i,
      source: @combat_system.HitSource::Passive(100),
      target_oids: [201 + i],
      result: @combat_proto.AttackResult::default(),
    }
    @combat_system.push_event(event)
  }

  passive_system(0.016)

  // Total calls should now be 5 (3 + 2)
  assert_eq(mock.call_count.val, 5)

  // Clean up
  @combat_system.clear_events()
}
