///|
/// One in-progress quest entry exposed by `quest_log` facade.
pub(all) struct QuestLogEntryInProgress {
  /// Quest id.
  quest_id : Int
  /// Quest display name.
  name : String
  /// Current progress string.
  progress_data : String
  /// Current phase index.
  phase : Int
  /// Current phase description from quest data.
  phase_description : String
} derive(Debug, ToJson, @json.FromJson)

///|
/// One completed quest entry exposed by `quest_log` facade.
pub(all) struct QuestLogEntryCompleted {
  /// Quest id.
  quest_id : Int
  /// Quest display name.
  name : String
  /// Completion timestamp from server snapshot.
  completion_time : Int64
} derive(Debug, ToJson, @json.FromJson)

///|
/// Quest-log snapshot returned by `get_snapshot()`.
pub(all) struct QuestLogSnapshot {
  /// In-progress quests.
  in_progress : Array[QuestLogEntryInProgress]
  /// Completed quests.
  completed : Array[QuestLogEntryCompleted]
} derive(Debug, ToJson, @json.FromJson)

///|
/// Returns current quest-log snapshot.
pub fn get_snapshot() -> QuestLogSnapshot {
  let raw = match active_module.val {
    Some(m) => m.quest_log_snapshot_raw()
    None => { in_progress: [], completed: [] }
  }
  let in_progress = raw.in_progress.map(fn(it) {
    QuestLogEntryInProgress::{
      quest_id: it.quest_id,
      name: it.name,
      progress_data: it.progress_data,
      phase: it.phase,
      phase_description: it.phase_description,
    }
  })
  in_progress.sort_by(fn(lhs, rhs) {
    if lhs.quest_id < rhs.quest_id {
      -1
    } else if lhs.quest_id > rhs.quest_id {
      1
    } else {
      0
    }
  })
  let completed = raw.completed.map(fn(it) {
    QuestLogEntryCompleted::{
      quest_id: it.quest_id,
      name: it.name,
      completion_time: it.completion_time,
    }
  })
  completed.sort_by(fn(lhs, rhs) {
    if lhs.quest_id < rhs.quest_id {
      -1
    } else if lhs.quest_id > rhs.quest_id {
      1
    } else {
      0
    }
  })
  { in_progress, completed }
}

///|
fn Module::quest_log_snapshot_raw(self : Module) -> QuestLogSnapshotRaw {
  let in_progress : Array[QuestLogInProgressRaw] = self.player_quest_log.val.in_progress
    .iter()
    .map(fn(it) {
      let (_, quest) = it
      QuestLogInProgressRaw::{
        quest_id: quest.quest_id,
        name: quest.quest_info.name,
        progress_data: quest.get_phase_progress(quest.phase),
        phase: quest.phase,
        phase_description: quest.quest_info.descriptions
        .get(quest.phase)
        .unwrap_or(""),
      }
    })
    .collect()
  let completed : Array[QuestLogCompletedRaw] = self.player_quest_log.val.completed
    .iter()
    .map(fn(it) {
      let (_, quest) = it
      QuestLogCompletedRaw::{
        quest_id: quest.quest_id,
        name: quest.quest_info.name,
        completion_time: quest.completion_time,
      }
    })
    .collect()
  { in_progress, completed }
}

///|
/// Returns monotonic quest-log revision.
pub fn revision() -> Int {
  quest_log_revision()
}

///|
/// Forfeits one in-progress quest.
pub fn forfeit(quest_id : Int) -> Result[Unit, String] {
  apply_forfeit_quest(quest_id)
}

///|
/// Registers quest packet handlers used by the runtime.
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "update_quest_info",
    @server_proto.Opcode::UPDATE_QUEST_INFO.int_value(),
    fn(json) raise {
      let msg : UpdateQuestInfoMessage = @json.from_json(json)
      handle_update_quest_info_message(msg)
    },
  )
}

///|
fn handle_update_quest_info_message(msg : UpdateQuestInfoMessage) -> Unit {
  match active_module.val {
    Some(m) => m.apply_update_quest_info(msg)
    None => ()
  }
}

///|
fn Module::apply_update_quest_info(
  self : Module,
  msg : UpdateQuestInfoMessage,
) -> Unit {
  match msg {
    QuestUpdate(quest_id~, ..) => {
      if self.player_quest_log.val.get_quest(quest_id) is None {
        ignore(
          self.player_quest_log.val.add_in_progress_quest(
            self.quests_resource,
            quest_id,
            "",
          ),
        )
      }
      bump_quest_log_revision()
    }
    QuestFinish(quest_id~, next_quest~, ..) => {
      mark_completed(
        self.player_quest_log.val,
        self.quests_resource,
        quest_id,
        0,
      )
      if next_quest > 0 &&
        self.player_quest_log.val.get_quest(next_quest) is None {
        ignore(
          self.player_quest_log.val.add_in_progress_quest(
            self.quests_resource,
            next_quest,
            "",
          ),
        )
      }
      bump_quest_log_revision()
    }
    QuestExpire(quest_id~) =>
      if self.player_quest_log.val.in_progress.contains(quest_id) {
        self.player_quest_log.val.in_progress.remove(quest_id) |> ignore
        bump_quest_log_revision()
      }
    QuestError(quest_id~) =>
      @log.warn("quest update failed", data={ "quest_id": quest_id })
    QuestFailure(operation~) =>
      @log.warn("quest operation failure", data={ "operation": operation })
    _ => ()
  }
}
