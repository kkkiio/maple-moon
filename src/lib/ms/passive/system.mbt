///|
/// Global SWORD_FA_FIGHTER passive instance (needs to be registered by game_scene)
pub let sword_fa_fighter_passive : SwordFaFighterPassive = SwordFaFighterPassive::new()

///|
/// Shared randomizer for passive skill probability checks.
let passive_randomizer_ref : Ref[@random.Rand] = Ref::new(@random.Rand::new())

///|
/// Global registry of passive skills
let passive_skills : Array[&PassiveSkill] = []

///|
let passive_reader_id : Ref[Int?] = Ref::new(None)

///|
/// Set the shared passive randomizer instance.
pub fn set_passive_randomizer(rand : @random.Rand) -> Unit {
  passive_randomizer_ref.val = rand
}

///|
fn default_trigger_extra_attack(
  attacker_oid : Int,
  skill_id : Int,
  targets : Array[Int],
) -> Unit {
  guard @combat_system.get_combat() is Some(combat) else { return }
  guard @character.get_character_by_oid(attacker_oid) is Some(character) else {
    return
  }
  combat.trigger_extra_attack(character, skill_id, targets)
}

///|
fn default_get_skill_level(attacker_oid : Int, skill_id : Int) -> Int {
  guard @player.get_player() is Some(player) else { return 0 }
  guard player.get_character().get_oid() == attacker_oid else { return 0 }
  player.get_skill_book().get_level(skill_id)
}

///|
fn default_get_skill_data(skill_id : Int) -> @skill.SkillData? {
  @skill.SkillData::get_cached(skill_id)
}

///|
/// Register a passive skill to the global registry
pub fn register_passive_skill(skill : &PassiveSkill) -> Unit {
  passive_skills.push(skill)
}

///|
fn get_passive_reader_id() -> Int {
  match passive_reader_id.val {
    Some(reader_id) => reader_id
    None => {
      let reader_id = @combat_system.register_reader()
      passive_reader_id.val = Some(reader_id)
      reader_id
    }
  }
}

///|
/// Passive skill system - processes hit events and triggers passive effects
/// Should be called after combat_system in the game loop
pub fn passive_system(_delta : Double) -> Unit {
  let ctx = PassiveContext::{
    randomizer: passive_randomizer_ref.val,
    get_character_fn: @character.get_character_by_oid,
    get_skill_level_fn: default_get_skill_level,
    get_skill_data_fn: default_get_skill_data,
    trigger_extra_attack_fn: default_trigger_extra_attack,
  }
  let reader_id = get_passive_reader_id()
  let events = @combat_system.read_new_events(reader_id)
  for event in events {
    // Notify all registered passive skills
    for skill in passive_skills {
      skill.on_hit(ctx, event)
    }
  }
  @combat_system.gc_consumed_events()
}
