///|
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
  available_skills : Map[Int, @skill.SkillData]
  watchers : Array[SkillBookWatcher]
}

///|
pub fn SkillBook::load(
  job : @job.Job,
  watchers : Array[SkillBookWatcher]
) -> @utils.Future[SkillBook] {
  job
  .get_all_subjobs()
  .flat_map(fn(it) { it.skill_ids.iter() })
  .map(fn(skill_id) { @skill.SkillData::load(skill_id) })
  .collect()
  |> @utils.Future::all_of()
  |> @utils.map(fn(it) {
    let available_skills = Map::new()
    for skill_data in it {
      let skill_data = skill_data.unwrap() // TODO: handle error
      available_skills.set(skill_data.id, skill_data)
    }
    SkillBook::new(available_skills, watchers)
  })
}

///|
pub fn SkillBook::new(
  available_skills : Map[Int, @skill.SkillData],
  watchers : Array[SkillBookWatcher]
) -> SkillBook {
  { skill_entries: Map::new(), available_skills, watchers }
}

///|
priv struct SkillEntry {
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
  self.available_skills[id].map_or(@immut/hashmap.new(), fn(
    skill_data
  ) -> @immut/hashmap.T[Int, Int] {
    skill_data.req_skills
  })
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
  self.watchers.retain(fn(listener) {
    listener({
      kind: "level",
      data_event: None,
      level_event: Some({ skill_id: id, level, available_sp: 0 }), // TODO: handle available_sp
    })
  })
}

///|
pub fn get_skill_data(self : SkillBook, id : Int) -> @skill.SkillData? {
  self.available_skills[id]
}

///|
pub typealias SkillBookWatcher = (SkillBookEvent) -> Bool

///|
pub struct SkillBookEvent {
  kind : String
  data_event : SkillBookDataEvent?
  level_event : SkillBookLevelEvent?
}

///|
pub struct SkillBookDataEvent {
  skills : Array[SkillUIData]
}

///|
pub struct SkillBookLevelEvent {
  skill_id : Int
  level : Int
  available_sp : Int
}

///| Data structure for representing a skill in the UI
pub struct SkillUIData {
  id : Int
  name : String
  desc : String
  level : Int
  master_level : Int
  icon : @resource.Image
  enabled : Bool
  can_raise : Bool
  job_level_value : Int
}

///| Get all skills for a given job level
fn get_skills_by_job_level(
  skillbook : SkillBook,
  job : @job.Job,
  job_level : @job.Level
) -> Array[SkillUIData] {
  let subid = job.get_subjob(job_level)
  let job_data = job.get_data_by_id(subid)
  job_data.skill_ids.filter_map(fn(skill_id) {
    let level = skillbook.get_level(skill_id)
    let masterlevel = skillbook.get_masterlevel(skill_id)
    match skillbook.get_skill_data(skill_id) {
      Some(data) =>
        if data.invisible && masterlevel == 0 {
          None
        } else {
          Some({
            id: skill_id,
            name: data.name,
            desc: data.desc.replace_all(old="\\n", new="\n"),
            level,
            master_level: masterlevel,
            icon: data.icons[0].bitmap.map_or(@resource.Image::new_pending(), fn(
              bitmap
            ) {
              bitmap.image
            }),
            enabled: check_required(skillbook, skill_id),
            can_raise: is_upgradable(
              skillbook, skill_id, level, 0, // beginner_sp
               0, // sp
            ),
            job_level_value: job_level.int_value(),
          })
        }
      None => None
    }
  })
}

///| Get all skills for the current player
fn get_player_all_skills(
  skillbook : SkillBook,
  player : @player.Player
) -> Array[SkillUIData] {
  let stats = player.get_stats()
  let job = stats.get_job()
  let curr_job_level = job.get_level()
  let beginner_sp = @math.minimum(stats.get_stat(@maple_stat.Id::LEVEL) - 1, 6) -
    beginner_skills
    .iter()
    .filter(fn(skill_id) { skillbook.get_level(skill_id.int_value()) > 0 })
    .count()
  let sp = stats.get_stat(@maple_stat.Id::SP)
  @job.get_levels(upto=curr_job_level)
  .flat_map(fn(level) {
    get_skills_by_job_level(skillbook, job, level)
    .iter()
    .map(fn(skill) {
      let data : SkillUIData = {
        ..skill,
        can_raise: is_upgradable(
          skillbook,
          skill.id,
          level.int_value(),
          beginner_sp,
          sp,
        ),
      }
      data
    })
  })
  .to_array()
}

///|
pub fn watch_skill_book(mod : Module, callback : SkillBookWatcher) -> Unit {
  let cont = match ((mod.player_getter)(), mod.skill_book) {
    (Some(player), Some(skillbook)) => {
      let skills = get_player_all_skills(skillbook, player)
      callback({
        kind: "data",
        data_event: Some({ skills, }),
        level_event: None,
      })
    }
    _ =>
      callback({
        kind: "data",
        data_event: Some({ skills: [] }),
        level_event: None,
      })
  }
  if not(cont) {
    return
  }
  mod.watchers.push(callback)
}

// fn emit_player_skill_book(
//   mod : Module,
// ) -> Unit {
//   guard let Some(callback) = mod.player_skill_book_watcher else { return }
//   callback(player_skill_book)
// }

///|
pub fn increase_sp(mod : Module, skill_id : Int) -> Unit {
  mod.packet_processor.send_message({ skill_id, }, log_level=@log.Level::INFO)
}

///| Requests a skill level increase by spending SP
priv struct SpendSPPacket {
  skill_id : Int
} derive(Show)

///|
impl @net.OutMessage for SpendSPPacket with pack(self) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_SP)
  ..write_time()
  ..write_int(self.skill_id)
}

///|
fn check_required(skillbook : SkillBook, id : Int) -> Bool {
  let required = skillbook.collect_required(id)
  for req in required {
    let (req_skill_id, req_level) = req
    let req_skill_level = skillbook.get_level(req_skill_id)
    if req_skill_level < req_level {
      return false
    }
  }
  return true
}

///|
fn joblevel_by_tab(t : Int) -> @job.Level {
  match t {
    1 => @job.Level::FIRST
    2 => @job.Level::SECOND
    3 => @job.Level::THIRD
    4 => @job.Level::FOURTH
    _ => @job.Level::BEGINNER
  }
}

///|
fn is_upgradable(
  skillbook : SkillBook,
  skill_id : Int,
  tab : Int,
  beginner_sp : Int,
  sp : Int
) -> Bool {
  let joblevel = joblevel_by_tab(tab)
  if joblevel == @job.Level::BEGINNER && beginner_sp <= 0 {
    return false
  }
  if tab != 0 && sp <= 0 {
    return false
  }
  let level = skillbook.get_level(skill_id)
  let mut masterlevel = skillbook.get_masterlevel(skill_id)
  if masterlevel == 0 {
    masterlevel = skillbook.get_skill_data(skill_id).unwrap().master_level // TODO: handle error
  }
  if level >= masterlevel {
    return false
  }
  if skill_id == @skill.SkillId::ANGEL_BLESSING.int_value() {
    false
  } else {
    check_required(skillbook, skill_id)
  }
}

///|
let beginner_skills : FixedArray[@skill.SkillId] = [
  @skill.SkillId::THREE_SNAILS,
  @skill.SkillId::HEAL,
  @skill.SkillId::FEATHER,
]

///|
test "parse skill desc" {
  let origin =
    #|[Master Level : 20]\nUse MP to attack an enemy twice.\nRequired Skill : #cAt least Level 1 on Energy Bolt#
  inspect!(
    markup_to_html!(origin),
    content="[Master Level : 20]<br/>Use MP to attack an enemy twice.<br/>Required Skill : <ul><li>At least Level 1 on Energy Bolt</li></ul>",
  )
}

///|
pub fn markup_to_html!(origin : String) -> String {
  // 1. replace '\' 'n' with "<br/>"
  // 2. replace #c{text}# with <li>{text}</li>
  let text = origin.replace_all(old="\\n", new="<br/>")
  if not(text.contains("#c")) {
    return text
  }
  let builder = StringBuilder::new(size_hint=text.length())
  let mut rest = text.view()
  let mut ul_added = false
  while rest.char_length_ge(1) {
    guard rest.find("#c") is Some(markup_start) else {
      builder.write_iter(rest.iter())
      break
    }
    builder.write_iter(rest.view(end_offset=markup_start).iter())
    rest = rest.view(start_offset=markup_start + 2)
    if not(ul_added) {
      builder.write_string("<ul>")
      ul_added = true
    }
    builder.write_string("<li>")
    guard rest.find("#") is Some(markup_end) else {
      fail!("Missing markup close")
    }
    builder.write_iter(rest.view(end_offset=markup_end).iter())
    builder.write_string("</li>")
    rest = rest.view(start_offset=markup_end + 1)
  }
  if ul_added {
    builder.write_string("</ul>")
  }
  builder.to_string()
}
