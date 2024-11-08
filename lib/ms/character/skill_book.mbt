// SkillBook stores all information about the skills of an individual character
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
  skill_level_listeners : Array[(Int, Int) -> Bool]
}

pub fn SkillBook::new() -> SkillBook {
  { skill_entries: Map::new(), skill_level_listeners: Array::new() }
}

struct SkillEntry {
  level : Int
  master_level : Int
}

pub fn get_level(self : SkillBook, id : Int) -> Int {
  self.skill_entries[id].map_or(0, fn(entry) -> Int { entry.level })
}

pub fn collect_required(
  self : SkillBook,
  id : Int
) -> @immut/hashmap.T[Int, Int]! {
  if self.skill_entries.contains(id) {
    return @skill.SkillData::get!(id).req_skills
  } else {
    return @immut/hashmap.T::new()
  }
}

pub fn get_masterlevel(self : SkillBook, id : Int) -> Int {
  let iter = self.skill_entries.get(id)
  match iter {
    Some(entry) => entry.master_level
    None => 0
  }
}

pub fn set_skill(
  self : SkillBook,
  id : Int,
  level : Int,
  master_level : Int,
  _expiration : Int
) -> Unit {
  self.skill_entries.set(id, { level, master_level })
  self.skill_level_listeners.retain(fn(listener) { listener(id, level) })
}

pub fn listen_skill_level_changes(
  self : SkillBook,
  listener : (Int, Int) -> Bool
) -> Unit {
  self.skill_level_listeners.push(listener)
}
