// SkillBook stores all information about the skills of an individual character
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
}

pub fn SkillBook::new() -> SkillBook {
  { skill_entries: Map::new() }
}

struct SkillEntry {
  level : Int
  masterlevel : Int
  expiration : Int
}

pub fn get_level(self : SkillBook, id : Int) -> Int {
  self.skill_entries[id].map_or(0, fn(entry) -> Int { entry.level })
}
