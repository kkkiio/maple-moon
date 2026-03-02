///|
/// SWORD_FA_FIGHTER passive skill implementation
/// Triggers an extra attack after normal attacks with certain probability
/// Only triggers when attacker is using one-handed sword.
pub struct SwordFaFighterPassive {}

///|
fn get_trigger_prob(ctx : PassiveContext, attacker_oid : Int) -> Double {
  let skill_id = @skill.SkillId::SWORD_FA_FIGHTER.int_value()
  let level = ctx.get_skill_level(attacker_oid, skill_id)
  guard level > 0 else { return 0.0 }
  guard ctx.get_skill_data(skill_id) is Some(skill_data) else { return 0.0 }
  guard skill_data.stats.get(level) is Some(stats) else { return 0.0 }
  stats.prop.to_double() / 100.0
}

///|
fn SwordFaFighterPassive::new() -> SwordFaFighterPassive {
  SwordFaFighterPassive::{  }
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
  _self : SwordFaFighterPassive,
  ctx : PassiveContext,
  event : @combat_system.HitEvent,
) -> Unit {
  // Only trigger on user input attacks, not passive attacks (prevent recursion)
  guard event.is_user_input() else { return }
  // Need at least one target hit
  guard event.target_oids().length() > 0 else { return }
  let attacker_oid = event.attacker_oid()
  guard ctx.get_character(attacker_oid) is Some(attacker) else { return }
  guard attacker.get_weapontype() == @weapon.Type::SWORD_1H else { return }
  let trigger_prob = get_trigger_prob(ctx, attacker_oid)
  guard trigger_prob > 0.0 else { return }
  // Apply probability check to each target with the shared passive randomizer.
  let targets = event
    .target_oids()
    .filter(fn(_oid) { @randx.below(ctx.randomizer, trigger_prob) })
  guard targets.length() > 0 else { return }
  ctx.trigger_extra_attack(
    attacker_oid,
    @skill.SkillId::SWORD_FA_FIGHTER.int_value(),
    targets,
  )
}
