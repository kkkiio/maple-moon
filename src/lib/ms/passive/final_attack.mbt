///|
/// SWORD_FA_FIGHTER passive skill implementation
/// Triggers an extra attack after normal attacks with certain probability
/// Skips weapon and job restrictions, only implements core probability logic
pub struct SwordFaFighterPassive {
  randomizer : @random.Rand
  /// Function to trigger extra attack (skill_id, targets) -> Unit
  /// Character is obtained from global player, so signature has one less param
  trigger_fn : (Int, Array[Int]) -> Unit
  /// Function to get trigger probability for current skill level
  get_trigger_prob_fn : () -> Double
}

///|
fn default_trigger_fn(skill_id : Int, targets : Array[Int]) -> Unit {
  guard @combat_system.get_combat() is Some(combat) else { return }
  guard @player.get_player() is Some(player) else { return }
  let character = player.get_character()
  combat.trigger_extra_attack(character, skill_id, targets)
}

///|
fn default_get_trigger_prob() -> Double {
  guard @player.get_player() is Some(player) else { return 0.0 }
  let skill_book = player.get_skill_book()
  let level = skill_book.get_level(@skill.SkillId::SWORD_FA_FIGHTER.int_value())
  guard level > 0 else { return 0.0 }
  guard @skill.SkillData::get_cached(
      @skill.SkillId::SWORD_FA_FIGHTER.int_value(),
    )
    is Some(skill_data) else {
    return 0.0
  }
  guard skill_data.stats.get(level) is Some(stats) else { return 0.0 }
  stats.prop.to_double() / 100.0
}

///|
fn SwordFaFighterPassive::new() -> SwordFaFighterPassive {
  {
    randomizer: @random.Rand::new(),
    trigger_fn: default_trigger_fn,
    get_trigger_prob_fn: default_get_trigger_prob,
  }
}

///|
pub fn SwordFaFighterPassive::new_with_trigger(
  trigger_fn : (Int, Array[Int]) -> Unit,
  get_trigger_prob_fn? : () -> Double = default_get_trigger_prob,
) -> SwordFaFighterPassive {
  { randomizer: @random.Rand::new(), trigger_fn, get_trigger_prob_fn }
}

///|
pub impl Default for SwordFaFighterPassive with default() {
  SwordFaFighterPassive::new()
}

///|
pub impl PassiveSkill for SwordFaFighterPassive with id(_self) -> Int {
  @skill.SkillId::SWORD_FA_FIGHTER.int_value()
}

///|
pub impl PassiveSkill for SwordFaFighterPassive with on_hit(
  self : SwordFaFighterPassive,
  _ctx : PassiveContext,
  event : @combat_system.HitEvent,
) -> Unit {
  // Only trigger on user input attacks, not passive attacks (prevent recursion)
  guard event.is_user_input() else { return }
  // Need at least one target hit
  guard event.target_oids().length() > 0 else { return }
  // Get trigger probability from injected function
  let trigger_prob = (self.get_trigger_prob_fn)()
  guard trigger_prob > 0.0 else { return }
  // Apply probability check to each target (reuse randomizer for proper distribution)
  let targets = event
    .target_oids()
    .filter(fn(_oid) { @randx.below(self.randomizer, trigger_prob) })
  guard targets.length() > 0 else { return }
  // Trigger the extra attack using injected function
  (self.trigger_fn)(@skill.SkillId::SWORD_FA_FIGHTER.int_value(), targets)
}
