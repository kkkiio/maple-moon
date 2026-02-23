///|
/// Test SwordFaFighterPassive on_hit with 100% probability
/// Verifies that trigger_fn is called when probability is 100%
test "sword_fa_fighter_100_percent_triggers" {
  let trigger_count = Ref::new(0)
  let triggered_targets : Ref[Array[Int]] = Ref::new([])

  // Mock trigger function
  let mock_trigger = fn(_skill_id : Int, targets : Array[Int]) -> Unit {
    trigger_count.val += 1
    triggered_targets.val = targets
  }

  // Mock probability function - always return 100%
  let mock_get_prob = fn() -> Double { 1.0 }

  // Create passive with mocked dependencies
  let passive = SwordFaFighterPassive::new_with_trigger(
    mock_trigger,
    get_trigger_prob_fn=mock_get_prob,
  )

  // Create event with 3 targets
  let event : @combat_system.HitEvent = {
    attacker_oid: 1,
    move_id: 100,
    source: @combat_system.HitSource::UserInput,
    target_oids: [101, 102, 103],
    result: @combat_proto.AttackResult::default(),
  }

  // Call on_hit
  passive.on_hit(PassiveContext::{  }, event)

  // With 100% probability, trigger should be called once with all 3 targets
  assert_eq(trigger_count.val, 1)
  assert_eq(triggered_targets.val.length(), 3)
}

///|
/// Test SwordFaFighterPassive on_hit with 0% probability
/// Verifies that trigger_fn is never called when probability is 0%
test "sword_fa_fighter_0_percent_no_trigger" {
  let trigger_count = Ref::new(0)

  // Mock trigger function
  let mock_trigger = fn(_skill_id : Int, _targets : Array[Int]) -> Unit {
    trigger_count.val += 1
  }

  // Mock probability function - always return 0%
  let mock_get_prob = fn() -> Double { 0.0 }

  // Create passive with mocked dependencies
  let passive = SwordFaFighterPassive::new_with_trigger(
    mock_trigger,
    get_trigger_prob_fn=mock_get_prob,
  )

  // Create event with 3 targets
  let event : @combat_system.HitEvent = {
    attacker_oid: 1,
    move_id: 100,
    source: @combat_system.HitSource::UserInput,
    target_oids: [101, 102, 103],
    result: @combat_proto.AttackResult::default(),
  }

  // Call on_hit
  passive.on_hit(PassiveContext::{  }, event)

  // With 0% probability, trigger should never be called
  assert_eq(trigger_count.val, 0)
}

///|
/// Test SwordFaFighterPassive on_hit trigger rate with 40% probability
/// Verifies frequency is statistically close to 40% by repeated sampling
test "sword_fa_fighter_40_percent_trigger_frequency" {
  let trigger_count = Ref::new(0)
  let trials = 5000

  let mock_trigger = fn(_skill_id : Int, _targets : Array[Int]) -> Unit {
    trigger_count.val += 1
  }

  let mock_get_prob = fn() -> Double { 0.4 }

  let passive = SwordFaFighterPassive::new_with_trigger(
    mock_trigger,
    get_trigger_prob_fn=mock_get_prob,
  )

  // Use single-target event so each on_hit call is one Bernoulli trial
  let event : @combat_system.HitEvent = {
    attacker_oid: 1,
    move_id: 100,
    source: @combat_system.HitSource::UserInput,
    target_oids: [101],
    result: @combat_proto.AttackResult::default(),
  }

  for _ in 0..<trials {
    passive.on_hit(PassiveContext::{  }, event)
  }

  let actual_rate = trigger_count.val.to_double() / trials.to_double()
  // Allow statistical fluctuation around 40%
  assert_true(actual_rate >= 0.35)
  assert_true(actual_rate <= 0.45)
}
