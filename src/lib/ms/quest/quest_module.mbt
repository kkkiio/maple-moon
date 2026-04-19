///|
pub(all) struct DemoQuestSelection {
  /// Selected quest id.
  quest_id : Int
  /// NPC template id bound to the selected quest.
  npc_id : Int
  /// Whether phase0 check includes a level requirement.
  has_level_check : Bool
} derive(Debug)

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
} derive(Debug)

///|
/// Raw completed quest-log entry exported for the `quest_log` facade.
pub(all) struct QuestLogCompletedRaw {
  /// Quest id.
  quest_id : Int
  /// Quest display name.
  name : String
  /// Completion timestamp.
  completion_time : Int64
} derive(Debug)

///|
/// Raw quest-log snapshot exported for the `quest_log` facade.
pub(all) struct QuestLogSnapshotRaw {
  /// In-progress entries.
  in_progress : Array[QuestLogInProgressRaw]
  /// Completed entries.
  completed : Array[QuestLogCompletedRaw]
} derive(Debug)

///|
/// 异步加载 Quest 资源,返回 (QuestResource, Json)
pub async fn load_quest_resource() -> (QuestResource, Json) {
  let quest_resource_loader = @resource.require_async_loader("quest")
  let raw = quest_resource_loader.load_resource(["nx"])
  let quests_resource : QuestResource = @json.from_json(raw)
  let quest_checks_raw = match raw {
    { "Check.img": check_raw, .. } => check_raw
    _ => Json::null()
  }
  (quests_resource, quest_checks_raw)
}

// ///|
// pub fn Module::make_handlers(
//   self : Module,
// ) -> Map[@server_proto.Opcode, (@net.InPacket) -> Unit] {
//   [
//     @net.make_handler(
//       @server_proto.Opcode::UPDATE_QUEST_INFO,
//       parse_update_quest_info,
//       fn(msg) { self.handle_update_quest_info(msg) },
//     ),
//   ]
//   |> Map::from_array
// }

// ///|
// pub fn Module::make_show_status_info_handlers(
//   self : Module,
// ) -> Map[Int, @game_mod.SubRouteHandler] {
//   {
//     1: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction raise {
//       let quest_id = recv.read_short()
//       let status = recv.read_byte()
//       match status {
//         0 => {
//           let action : &@game_mod.SubRouteAction = ShowForfeitQuestAction::new(
//             quest_id, self,
//           )
//           action
//         }
//         2 => {
//           let action : &@game_mod.SubRouteAction = ShowCompleteQuestAction::new(
//             { quest_id, completion_time: recv.read_long() },
//             self,
//           )
//           action
//         }
//         _ => {
//           let action : &@game_mod.SubRouteAction = ShowUpdateQuestAction::new(
//             { quest_id, progress_data: recv.read_string() },
//             self,
//           )
//           action
//         }
//       }
//     },
//     3: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction raise {
//       let white = recv.read_bool()
//       let gain = recv.read_int()
//       let in_chat = recv.read_bool()
//       let bonus_event_exp = recv.read_int()
//       let third_monster_kill_event = recv.read_byte()
//       let _ = recv.read_byte() // rip_byte
//       let wedding_bonus = recv.read_int()
//       let quest_bonus_rate = if in_chat { Some(recv.read_byte()) } else { None }
//       let party_bonus_multiplier = recv.read_byte()
//       let party_bonus = recv.read_int()
//       let equip_bonus = recv.read_int()
//       let internet_cafe_bonus = recv.read_int()
//       let rainbow_week_bonus = recv.read_int()
//       let action : &@game_mod.SubRouteAction = ShowExpGainAction::new({
//         white,
//         gain,
//         in_chat,
//         bonus_event_exp,
//         third_monster_kill_event,
//         wedding_bonus,
//         quest_bonus_rate,
//         party_bonus_multiplier,
//         party_bonus,
//         equip_bonus,
//         internet_cafe_bonus,
//         rainbow_week_bonus,
//       })
//       action
//     },
//   }
// }

///|
/// PlayerQuestLog stores information on the quest log of an individual character
pub(all) struct PlayerQuestLog {
  in_progress : Map[Int, InProgressQuest]
  completed : Map[Int, CompletedQuest]
} derive(Debug, Default)

///|
pub(all) struct InProgressQuest {
  quest_id : Int
  quest_info : NxQuestInfo
  checks : Array[NxQuestPhaseChecks]
  acts : Array[NxQuestPhaseAct]
  mut progress_data : String
  mut phase : Int
  info_number_progress_map : Map[Int, String]
} derive(Debug)

///|
pub fn InProgressQuest::get_phase_progress(
  self : InProgressQuest,
  phase : Int,
) -> String {
  self.checks
  .get(phase)
  .bind(fn(it) { it.info_number })
  .bind(fn(it) { self.info_number_progress_map.get(it) })
  .unwrap_or(self.progress_data)
}

///|
pub(all) struct CompletedQuest {
  quest_id : Int
  quest_info : NxQuestInfo
  completion_time : Int64
} derive(Debug)

///|
pub fn PlayerQuestLog::get_quest(
  self : PlayerQuestLog,
  quest_id : Int,
) -> StartedQuest? {
  if self.in_progress.get(quest_id) is Some(in_progress_quest) {
    Some(InProgress(in_progress_quest))
  } else if self.completed.get(quest_id) is Some(completed_quest) {
    Some(Completed(completed_quest))
  } else {
    None
  }
}

///|
pub enum StartedQuest {
  InProgress(InProgressQuest)
  Completed(CompletedQuest)
} derive(Debug)

// ///|
// pub fn parse_player_quest_info(
//   recv : @net.InPacket,
// ) -> PlayerQuestLogInfo raise {
//   let started_size = recv.read_short()
//   let started = []
//   let completed = []
//   for i in 0..<started_size {
//     let quest_id = recv.read_short()
//     let progress_data = recv.read_string()
//     started.push((quest_id, progress_data))
//   }
//   let completed_size = recv.read_short()
//   for i in 0..<completed_size {
//     let quest_id = recv.read_short()
//     let completion_time = recv.read_long()
//     completed.push((quest_id, completion_time))
//   }
//   { started, completed }
// }

// ///|
// fn parse_update_quest_info(
//   recv : @net.InPacket,
// ) -> UpdateQuestInfoMessage raise {
//   let operation = recv.read_byte()
//   match operation {
//     6 => {
//       // Add quest time limit: short size, short quest_id, int time
//       let size = recv.read_short()
//       let quest_id = recv.read_short()
//       let time = recv.read_int()
//       AddQuestTimeLimit(size, quest_id, time)
//     }
//     7 => {
//       // Remove quest time limit: short position, short quest_id
//       let position = recv.read_short()
//       let quest_id = recv.read_short()
//       RemoveQuestTimeLimit(position, quest_id)
//     }
//     8 => {
//       // Quest update/finish: short quest_id, int npc, (short next_quest or int 0)
//       let quest_id = recv.read_short()
//       let npc = recv.read_int()
//       if recv.available() == 2 {
//         let next_quest = recv.read_short()
//         QuestFinish(quest_id, npc, next_quest)
//       } else {
//         recv.read_int() |> ignore // 0
//         QuestUpdate(quest_id, npc)
//       }
//     }
//     0x0A => {
//       // Quest error: short quest_id
//       let quest_id = recv.read_short()
//       QuestError(quest_id)
//     }
//     0x0F => {
//       // Quest expire: short quest_id  
//       let quest_id = recv.read_short()
//       QuestExpire(quest_id)
//     }
//     _ =>
//       // For other operation types (0x0B, 0x0D, 0x0E), just store the operation
//       match operation {
//         0x0B => QuestFailure(NoMeso)
//         0x0D => QuestFailure(WornByCharacter)
//         0x0E => QuestFailure(NotHavingItem)
//         _ => fail("Unknown quest failure operation: \{operation}")
//       }
//   }
// }

// ///|
// impl @game_mod.SubRouteAction for ShowForfeitQuestAction with handle(self) -> Unit {
//   self.mod.player_quest_log.val.in_progress.remove(self.quest_id)
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
// }

// ///|
// impl @game_mod.SubRouteAction for ShowCompleteQuestAction with handle(self) -> Unit {
//   let quest_id = self.message.quest_id
//   let completion_time = self.message.completion_time
//   let quest_info = self.mod.quests_resource.quest_info_map.get(quest_id)
//   let quest_info = if quest_info is Some(quest_info) {
//     quest_info
//   } else {
//     @log.warn("quest info not found", data={ "quest_id": quest_id })
//     {
//       name: "Unknown Quest \{quest_id}",
//       parent: None,
//       area: 0,
//       order: None,
//       auto_complete: false,
//       auto_start: false,
//       one_shot: false,
//       descriptions: [],
//     }
//   }
//   self.mod.player_quest_log.val.in_progress.remove(quest_id)
//   self.mod.player_quest_log.val.completed[quest_id] = {
//     quest_id,
//     quest_info,
//     completion_time,
//   }
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
//   self.mod.map_quests.update_quest(quest_id)
// }

// ///|
// impl @game_mod.SubRouteAction for ShowUpdateQuestAction with handle(self) -> Unit {
//   let player_quest_log = self.mod.player_quest_log.val
//   let quest = if player_quest_log.in_progress.get(self.message.quest_id)
//     is Some(quest) {
//     quest
//   } else {
//     // accept quest
//     guard self.mod.quests_resource.quest_info_map.get(self.message.quest_id)
//       is Some(quest_info) else {
//       @log.warn("quest info not found", data={
//         "quest_id": self.message.quest_id,
//       })
//       return
//     }
//     let quest = {
//       quest_id: self.message.quest_id,
//       quest_info,
//       checks: [],
//       acts: [],
//       progress_data: "",
//       phase: 0,
//       info_number_progress_map: {},
//     }
//     player_quest_log.in_progress.set(self.message.quest_id, quest)
//     quest
//   }
//   quest.progress_data = self.message.progress_data
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
//   self.mod.map_quests.update_quest(self.message.quest_id) // TODO: convert to listener
// }

// ///|
// impl @game_mod.SubRouteAction for ShowExpGainAction with handle(_) -> Unit {
//   // TODO: Add UI handling to display EXP gain popup/notification
//   // TODO: Add any quest-related EXP gain processing if needed
// }
