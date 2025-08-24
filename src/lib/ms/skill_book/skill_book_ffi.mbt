///|
pub fn watch_skill_book(mod : Module, callback : SkillBookWatcher) -> Unit {
  let cont = match ((mod.player_getter)(), mod.player_skill_book) {
    (Some(player), Some((skillbook, _))) => {
      let skill_groups = get_player_skill_groups(skillbook, player)
      callback({
        kind: "data",
        data_event: Some({ skill_groups, }),
        level_event: None,
      })
    }
    _ =>
      callback({
        kind: "data",
        data_event: Some({ skill_groups: [] }),
        level_event: None,
      })
  }
  if not(cont) {
    return
  }
  mod.watchers.push(callback)
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
    let master_level = skillbook.get_masterlevel(skill_id)
    match skillbook.get_skill_data(skill_id) {
      Some(data) =>
        if data.invisible && master_level == 0 {
          None
        } else {
          let master_level = match master_level {
            0 =>
              skillbook
              .get_skill_data(skill_id)
              .map_or(0, fn(data) { data.master_level })
            v => v
          }
          Some({
            id: skill_id,
            name: data.name,
            desc: (try? markup_to_html(data.desc)).or(data.desc),
            level,
            master_level,
            icon: data.icons[0].bitmap.map_or(@resource.Image::new_pending(), fn(
              bitmap
            ) {
              bitmap.image
            }),
            enabled: check_required(skillbook, skill_id),
            job_level_value: job_level.int_value(),
          })
        }
      None => None
    }
  })
}

///| Get all skills for the current player, grouped by job level
fn get_player_skill_groups(
  skillbook : SkillBook,
  player : @player.Player
) -> Array[SkillGroup] {
  let stats = player.get_stats()
  let job = stats.get_job()
  let curr_job_level = job.get_level()
  @job.get_levels(upto=curr_job_level)
  .map(fn(level) {
    let skills = get_skills_by_job_level(skillbook, job, level)
      .iter()
      .map(fn(skill) {
        let data : SkillUIData = { ..skill }
        data
      })
      .to_array()
    { job_level_value: level.int_value(), skills }
  })
  .to_array()
}

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

///| Data structure for representing a skill in the UI
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
pub fn transfer_one_sp(
  mod : Module,
  job_level : Int,
  from_skill_id : Int,
  to_skill_id : Int
) -> String {
  let item_id = match job_level {
    1 => SpResetItemId::SP_RESET_1ST_JOB
    2 => SpResetItemId::SP_RESET_2ND_JOB
    3 => SpResetItemId::SP_RESET_3RD_JOB
    4 => SpResetItemId::SP_RESET_4TH_JOB
    _ => return "invalid job level \{job_level}"
  }
  guard mod.inventory.find_item(@inventory.TypeId::CASH, item_id.int_value())
    is Some(slot_no) else {
    return "not found item id \{item_id.int_value()}"
  }
  mod.network.send_message({
    slot_no: slot_no.inner(),
    item_id: item_id.int_value(),
    to: to_skill_id,
    from: from_skill_id,
  })
  ""
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

///| 
priv struct SpResetItemMessage {
  slot_no : Int
  item_id : Int
  to : Int
  from : Int
} derive(Show)

///|
impl @net.OutMessage for SpResetItemMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::USE_CASH_ITEM)
  // check Cosmic/src/main/java/net/server/channel/handlers/UseCashItemHandler.java
  packet
  ..write_short(self.slot_no)
  ..write_int(self.item_id)
  ..write_int(self.to)
  ..write_int(self.from)
  packet
}
