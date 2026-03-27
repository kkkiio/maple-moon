///|
using @quest {
  type QuestResource,
  type PlayerQuestLog,
  type InProgressQuest,
  type CompletedQuest,
}

///|
using @server_proto {type PlayerQuestLogInfo, type UpdateQuestInfoMessage}

///|
struct Module {
  quests_resource : QuestResource
  player_quest_log : Ref[PlayerQuestLog]
}

///|
let active_module : Ref[Module?] = Ref::new(None)

///|
/// Quest-log change event bus.
let quest_log_event_bus : @event.Events[(PlayerQuestLog) -> Bool] = @event.Events::new()

///|
/// Raw in-progress quest-log entry exported for the `quest_log` facade.
pub(all) struct QuestLogInProgressRaw {
  /// Quest id.
  quest_id : Int
  /// Quest display name.
  name : String
  /// Current progress text.
  progress_data : String
  /// Current phase index.
  phase : Int
} derive(Show)

///|
/// Raw completed quest-log entry exported for the `quest_log` facade.
pub(all) struct QuestLogCompletedRaw {
  /// Quest id.
  quest_id : Int
  /// Quest display name.
  name : String
  /// Completion timestamp.
  completion_time : Int64
} derive(Show)

///|
/// Raw quest-log snapshot exported for the `quest_log` facade.
pub(all) struct QuestLogSnapshotRaw {
  /// In-progress entries.
  in_progress : Array[QuestLogInProgressRaw]
  /// Completed entries.
  completed : Array[QuestLogCompletedRaw]
} derive(Show)

///|
let quest_log_revision_ref : Ref[Int] = Ref::new(0)

///|
/// Returns monotonic revision used by quest-log query caches.
pub fn quest_log_revision() -> Int {
  quest_log_revision_ref.val
}

///|
/// Applies quest forfeit to runtime state and notifies the server.
pub fn apply_forfeit_quest(quest_id : Int) -> Result[Unit, String] {
  match active_module.val {
    Some(m) =>
      if m.player_quest_log.val.in_progress.contains(quest_id) {
        m.player_quest_log.val.in_progress.remove(quest_id) |> ignore
        @game_server.send(
          @server_proto.QuestActionMessage::ForfeitQuest(quest_id~),
        )
        bump_quest_log_revision()
        Ok(())
      } else {
        Err("quest \{quest_id} is not in progress")
      }
    None => Err("quest module is not active")
  }
}

///|
/// Applies `SET_FIELD` quest log snapshot to active quest module.
pub fn handle_player_quest_info(player_quests : PlayerQuestLogInfo) -> Unit {
  match active_module.val {
    Some(m) => m.handle_player_quest_info(player_quests)
    None => ()
  }
}

///|
/// Returns current runtime player quest log snapshot for cross-module queries.
pub fn current_player_quest_log() -> PlayerQuestLog {
  match active_module.val {
    Some(m) => m.player_quest_log.val
    None => @quest.PlayerQuestLog::default()
  }
}

///|
fn bump_quest_log_revision() -> Unit {
  quest_log_revision_ref.val = quest_log_revision_ref.val + 1
}

///|
/// 初始化 quest_log 模块
pub fn setup(quests_resource : QuestResource) -> Unit {
  let mod = {
    quests_resource,
    player_quest_log: Ref::new({ in_progress: {}, completed: {} }),
  }
  active_module.val = Some(mod)
  bump_quest_log_revision()
}

///|
pub fn Module::handle_player_quest_info(
  self : Module,
  player_quests : PlayerQuestLogInfo,
) -> Unit {
  self.player_quest_log.val = parse_player_quest_log(
    self.quests_resource,
    player_quests,
  )
  bump_quest_log_revision()
}

///|
fn parse_player_quest_log(
  quests_resource : QuestResource,
  player_quests : PlayerQuestLogInfo,
) -> PlayerQuestLog {
  let quest_log : PlayerQuestLog = { in_progress: {}, completed: {} }
  let mut last_in_progress_quest : InProgressQuest? = None
  quest_loop~: for it in player_quests.started {
    let (id, progress_data) = it
    let quest_info = quests_resource.quest_info_map.get(id)
    if quest_info is None {
      // maybe a infoNumber
      if last_in_progress_quest is Some(last_in_progress_quest) {
        for i, check in last_in_progress_quest.checks {
          if check.info_number is Some(info_number) && info_number == id { // is a infoNumber
            last_in_progress_quest.phase = i
            last_in_progress_quest.info_number_progress_map[id] = progress_data
            continue quest_loop~
          }
        }
      }
    }
    let quest = quest_log.add_in_progress_quest(
      quests_resource, id, progress_data,
    )
    last_in_progress_quest = Some(quest)
  }
  for it in player_quests.completed {
    let (quest_id, completion_time) = it
    let quest_info = quests_resource.quest_info_map.get(quest_id)
    let quest_info = if quest_info is Some(quest_info) {
      quest_info
    } else {
      @log.warn("quest info not found", data={ "quest_id": quest_id })
      {
        name: "Unknown Quest \{quest_id}",
        parent: None,
        area: 0,
        order: None,
        auto_complete: false,
        auto_start: false,
        one_shot: false,
        descriptions: [],
      }
    }
    quest_log.completed[quest_id] = CompletedQuest::{
      quest_id,
      quest_info,
      completion_time,
    }
  }
  quest_log
}

///|
fn PlayerQuestLog::add_in_progress_quest(
  self : PlayerQuestLog,
  quests_resource : QuestResource,
  quest_id : Int,
  progress_data : String,
) -> InProgressQuest {
  let id = quest_id
  let quest_info = quests_resource.quest_info_map.get(quest_id)
  let quest_info = if quest_info is Some(quest_info) {
    quest_info
  } else {
    @log.warn("quest info not found", data={ "id": id })
    {
      name: "Unknown Quest \{id}",
      parent: None,
      area: 0,
      order: None,
      auto_complete: false,
      auto_start: false,
      one_shot: false,
      descriptions: [],
    }
  }
  let checks = quests_resource.quest_checks_map.get(id)
  let quest = InProgressQuest::{
    quest_id: id,
    quest_info,
    checks: checks.unwrap_or([]),
    acts: quests_resource.quest_acts_map.get(id).unwrap_or([]),
    progress_data,
    phase: 1, // phase 0 is start requirements
    info_number_progress_map: {},
  }
  self.in_progress[id] = quest
  quest
}

///|
fn mark_completed(
  qlog : PlayerQuestLog,
  quests_resource : QuestResource,
  quest_id : Int,
  completion_time : Int64,
) -> Unit {
  qlog.in_progress.remove(quest_id) |> ignore
  let quest_info = match quests_resource.quest_info_map.get(quest_id) {
    Some(quest_info) => quest_info
    None => {
      @log.warn("quest info not found", data={ "quest_id": quest_id })
      {
        name: "Unknown Quest \{quest_id}",
        parent: None,
        area: 0,
        order: None,
        auto_complete: false,
        auto_start: false,
        one_shot: false,
        descriptions: [],
      }
    }
  }
  qlog.completed[quest_id] = { quest_id, quest_info, completion_time }
}
