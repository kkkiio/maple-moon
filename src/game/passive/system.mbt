///|
/// Global SWORD_FA_FIGHTER passive instance (needs to be registered by game_scene)
pub let sword_fa_fighter_passive : SwordFaFighterPassive = SwordFaFighterPassive()

///|
/// Shared randomizer for passive skill probability checks.
let passive_randomizer_ref : Ref[@random.Rand] = Ref(@random.Rand::new())

///|
/// Global registry of passive skills
let passive_skills : Array[&PassiveSkill] = []

///|
let passive_reader : Ref[@event.EventReader[@combat_system.HitEvent]?] = Ref(
  None,
)

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
  match @skill_cast.get_skill_move(skill_id) {
    Some(act) => combat.trigger_extra_attack(character, act, targets)
    None => ()
  }
}

///|
fn default_get_skill_level(attacker_oid : Int, skill_id : Int) -> Int {
  guard @player.get_player() is Some(player) else { return 0 }
  let character = @combat_system.CombatCharacter::get_character(player)
  guard character.get_oid() == attacker_oid else { return 0 }
  @legacy_types.SkillBook::get_level(
    @combat_system.CombatCharacter::get_skill_book(player),
    skill_id,
  )
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
fn get_passive_reader() -> @event.EventReader[@combat_system.HitEvent] {
  match passive_reader.val {
    Some(reader) => reader
    None => {
      let reader : @event.EventReader[@combat_system.HitEvent] = @event.EventReader()
      passive_reader.val = Some(reader)
      reader
    }
  }
}

///|
/// Passive skill system - processes hit events and triggers passive effects
/// Should be called after combat_system in the game loop
pub fn passive_system(_world : @ecs.World) -> Unit {
  let ctx = PassiveContext::{
    randomizer: passive_randomizer_ref.val,
    get_character_equips_fn: fn(oid : Int) -> @equip.CharEquips? {
      guard @character.get_character_by_oid(oid) is Some(character) else {
        return None
      }
      Some(character.get_look().get_equips())
    },
    get_skill_level_fn: default_get_skill_level,
    get_skill_data_fn: default_get_skill_data,
    trigger_extra_attack_fn: default_trigger_extra_attack,
  }
  let reader = get_passive_reader()
  let events = @combat_system.hit_event_bus.read(reader)
  for event in events {
    // Notify all registered passive skills
    for skill in passive_skills {
      skill.on_hit(ctx, event)
    }
  }
}
