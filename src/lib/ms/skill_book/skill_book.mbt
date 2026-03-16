///|
struct SkillBook {
  skill_entries : Map[Int, SkillEntry]
  available_skills : Map[Int, @skill.SkillData]
  watchers : Array[SkillBookWatcher]
}

///|
pub async fn SkillBook::load(
  job : @job.Job,
  watchers : Array[SkillBookWatcher],
) -> SkillBook {
  let async_ops = job
    .get_all_subjobs()
    .flat_map(fn(it) { it.skill_ids.iter() })
    .map(fn(skill_id) { async fn() { @skill.SkillData::load(skill_id) } })
    |> Array::from_iter
  let it = @js.async_all(async_ops)
  let available_skills = Map::new()
  for skill_data in it {
    let skill_data = skill_data
    available_skills.set(skill_data.id, skill_data)
  }
  SkillBook::new(available_skills, watchers)
}

///|
pub fn SkillBook::new(
  available_skills : Map[Int, @skill.SkillData],
  watchers : Array[SkillBookWatcher],
) -> SkillBook {
  { skill_entries: Map::new(), available_skills, watchers }
}

///|
priv struct SkillEntry {
  level : Int
  master_level : Int
}

///|
pub impl @legacy_types.SkillBook for SkillBook with get_level(
  self : SkillBook,
  id : Int,
) -> Int {
  self.skill_entries.get(id).map_or(0, fn(entry) -> Int { entry.level })
}

///|
pub fn SkillBook::collect_required(
  self : SkillBook,
  id : Int,
) -> @immut/hashmap.HashMap[Int, Int] {
  self.available_skills
  .get(id)
  .map_or(@immut/hashmap.new(), fn(
    skill_data,
  ) -> @immut/hashmap.HashMap[Int, Int] {
    skill_data.req_skills
  })
}

///|
pub fn SkillBook::get_masterlevel(self : SkillBook, id : Int) -> Int {
  let iter = self.skill_entries.get(id)
  match iter {
    Some(entry) => entry.master_level
    None => 0
  }
}

///|
pub impl @legacy_types.SkillBook for SkillBook with set_skill(
  self : SkillBook,
  id : Int,
  level : Int,
  master_level : Int,
  _expiration : Int,
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
pub fn SkillBook::get_skill_data(
  self : SkillBook,
  id : Int,
) -> @skill.SkillData? {
  self.available_skills.get(id)
}

///|
pub type SkillBookWatcher = (SkillBookEvent) -> Bool

///|
pub fn increase_sp(skill_id : Int) -> Unit {
  @game_server.send(@server_proto.SpendSPMessage::{ skill_id, })
}

///|
/// Requests a skill level increase by spending SP

// ///|
// fn is_upgradable(
//   skillbook : SkillBook,
//   skill_id : Int,
//   tab : Int,
//   beginner_sp : Int,
//   sp : Int
// ) -> Bool {
//   let joblevel = joblevel_by_tab(tab)
//   if joblevel == @job.Level::BEGINNER && beginner_sp <= 0 {
//     return false
//   }
//   if tab != 0 && sp <= 0 {
//     return false
//   }
//   let level = skillbook.get_level(skill_id)
//   let mut masterlevel = skillbook.get_masterlevel(skill_id)
//   if masterlevel == 0 {
//     masterlevel = skillbook.get_skill_data(skill_id).unwrap().master_level // TODO: handle error
//   }
//   if level >= masterlevel {
//     return false
//   }
//   if skill_id == @skill.SkillId::ANGEL_BLESSING.int_value() {
//     false
//   } else {
//     check_required(skillbook, skill_id)
//   }
// }

// let beginner_skills : FixedArray[@skill.SkillId] = [
//   @skill.SkillId::THREE_SNAILS,
//   @skill.SkillId::HEAL,
//   @skill.SkillId::FEATHER,
// ]

///|
test "parse skill desc" {
  let origin =
    #|[Master Level : 20]\nUse MP to attack an enemy twice.\nRequired Skill : #cAt least Level 1 on Energy Bolt#
  inspect(
    markup_to_html(origin),
    content=(
      #|<span style="color: black">[Master Level : 20]</span><br/>
      #|<span style="color: black">Use MP to attack an enemy twice.</span><br/>
      #|<span style="color: black">Required Skill : </span><div style="display: list-item;">At least Level 1 on Energy Bolt</div>
    ),
  )
}

///|
pub fn markup_to_html(origin : String) -> String raise {
  let nodes = @markup_text.parse_markup(origin, tag_map)
  let html = @markup_text.to_html(
    nodes,
    { color: @struct.ColorName::BLACK, bold: false },
    @markup_text.color_map,
    { 'c': fn(_, v) { "<div style=\"display: list-item;\">\{v}</div>" } },
  )
  html
}

///|
let tag_map : Map[Char, @markup_text.MarkupType] = @markup_text.common_tags
  .iter()
  .concat([('c', @markup_text.MarkupType::Pair)].iter())
  |> Map::from_iter

///|
pub struct SkillBookEvent {
  kind : String
  data_event : SkillBookDataEvent?
  level_event : SkillBookLevelEvent?
}

///|
pub struct SkillBookDataEvent {
  skill_groups : Array[SkillGroup]
}

///|
pub struct SkillGroup {
  job_level_value : Int
  skills : Array[SkillUIData]
}

///|
pub struct SkillBookLevelEvent {
  skill_id : Int
  level : Int
  available_sp : Int
}

///|
/// Data structure for representing a skill in the UI
pub struct SkillUIData {
  id : Int
  name : String
  desc : String
  level : Int
  master_level : Int
  icon : @resource.Image
  enabled : Bool
  job_level_value : Int
}

///|
enum SpResetItemId {
  SP_RESET_1ST_JOB = 5050001
  SP_RESET_2ND_JOB = 5050002
  SP_RESET_3RD_JOB = 5050003
  SP_RESET_4TH_JOB = 5050004
} derive(Show)

///|
pub fn SpResetItemId::int_value(self : SpResetItemId) -> Int = "%identity"
