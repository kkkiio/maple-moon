///|
/// Global SWORD_FA_FIGHTER passive instance (needs to be registered by game_scene)
pub let sword_fa_fighter_passive : SwordFaFighterPassive = SwordFaFighterPassive::new()

///|
/// Global registry of passive skills
let passive_skills : Array[&PassiveSkill] = []

///|
let passive_reader_id : Ref[Int?] = Ref::new(None)

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
  let ctx = PassiveContext::{  }
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
