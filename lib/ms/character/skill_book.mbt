///|
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
  skill_level_listeners : Array[(Int, Int) -> Bool]
  available_skills : Map[Int, @skill.SkillData]
}

///|
pub fn SkillBook::load(job : @job.Job) -> @utils.Future[SkillBook] {
  job
  .get_all_subjobs()
  .flat_map(fn(it) { it.skill_ids.iter() })
  .map(fn(skill_id) { @skill.SkillData::load(skill_id) })
  .collect()
  |> @utils.Future::all_of()
  |> @utils.map(
    fn(it) {
      let available_skills = Map::new()
      for skill_data in it {
        let skill_data = skill_data.unwrap() // TODO: handle error
        available_skills.set(skill_data.id, skill_data)
      }
      SkillBook::new(available_skills)
    },
  )
}

///|
pub fn SkillBook::new(
  available_skills : Map[Int, @skill.SkillData]
) -> SkillBook {
  {
    skill_entries: Map::new(),
    skill_level_listeners: Array::new(),
    available_skills,
  }
}

///|
struct SkillEntry {
  level : Int
  master_level : Int
}

///|
pub fn get_level(self : SkillBook, id : Int) -> Int {
  self.skill_entries[id].map_or(0, fn(entry) -> Int { entry.level })
}

///|
pub fn collect_required(
  self : SkillBook,
  id : Int
) -> @immut/hashmap.T[Int, Int] {
  self.available_skills[id].map_or(
    @immut/hashmap.new(),
    fn(skill_data) -> @immut/hashmap.T[Int, Int] { skill_data.req_skills },
  )
}

///|
pub fn get_masterlevel(self : SkillBook, id : Int) -> Int {
  let iter = self.skill_entries.get(id)
  match iter {
    Some(entry) => entry.master_level
    None => 0
  }
}

///|
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

///|
pub fn listen_skill_level_changes(
  self : SkillBook,
  listener : (Int, Int) -> Bool
) -> Unit {
  self.skill_level_listeners.push(listener)
}

///|
pub fn get_skill_data(self : SkillBook, id : Int) -> @skill.SkillData? {
  self.available_skills[id]
}
