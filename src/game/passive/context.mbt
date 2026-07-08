///|
/// Runtime context for passive skills.
///
/// Passive skills can use this context to query attacker state,
/// consume shared randomness, and trigger follow-up attacks.
pub(all) struct PassiveContext {
  randomizer : @random.Rand
  get_character_equips_fn : (Int) -> @equip.CharEquips?
  get_skill_level_fn : (Int, Int) -> Int
  get_skill_data_fn : (Int) -> @skill.SkillData?
  trigger_extra_attack_fn : (Int, Int, Array[Int]) -> Unit
}

///|
/// Get character equips by object id.
pub fn PassiveContext::get_character_equips(
  self : PassiveContext,
  oid : Int,
) -> @equip.CharEquips? {
  (self.get_character_equips_fn)(oid)
}

///|
/// Trigger an extra attack for `attacker_oid`.
pub fn PassiveContext::trigger_extra_attack(
  self : PassiveContext,
  attacker_oid : Int,
  skill_id : Int,
  targets : Array[Int],
) -> Unit {
  (self.trigger_extra_attack_fn)(attacker_oid, skill_id, targets)
}

///|
/// Get skill level by attacker object id and skill id.
pub fn PassiveContext::get_skill_level(
  self : PassiveContext,
  attacker_oid : Int,
  skill_id : Int,
) -> Int {
  (self.get_skill_level_fn)(attacker_oid, skill_id)
}

///|
/// Get cached skill data by skill id.
pub fn PassiveContext::get_skill_data(
  self : PassiveContext,
  skill_id : Int,
) -> @skill.SkillData? {
  (self.get_skill_data_fn)(skill_id)
}
