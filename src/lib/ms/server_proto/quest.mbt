/// Messages for quest updates and quest-related status info.

///|
pub(all) enum QuestFailureOperation {
  /// Player does not have enough meso.
  NoMeso
  /// Required equipment is currently worn.
  WornByCharacter
  /// Required item is missing.
  NotHavingItem
} derive(Debug, ToJson, @json.FromJson)

///|
pub(all) enum UpdateQuestInfoMessage {
  /// Add quest timer entry.
  AddQuestTimeLimit(size~ : Int, quest_id~ : Int, time~ : Int)
  /// Remove quest timer entry.
  RemoveQuestTimeLimit(position~ : Int, quest_id~ : Int)
  /// Quest state updated.
  QuestUpdate(quest_id~ : Int, npc_id~ : Int)
  /// Quest finished and may chain to next quest.
  QuestFinish(quest_id~ : Int, npc_id~ : Int, next_quest~ : Int)
  /// Quest update failed.
  QuestError(quest_id~ : Int)
  /// Quest expired by timeout.
  QuestExpire(quest_id~ : Int)
  /// Quest operation failure detail.
  QuestFailure(operation~ : QuestFailureOperation)
} derive(Debug, ToJson, @json.FromJson)

///|
pub impl ServerMessage for UpdateQuestInfoMessage with type_code() {
  Opcode::UPDATE_QUEST_INFO.int_value()
}

///|
pub(all) enum QuestActionMessage {
  /// Start one quest from NPC dialogue.
  StartQuest(quest_id~ : Int, npc_id~ : Int)
  /// Complete one quest from NPC dialogue.
  CompleteQuest(quest_id~ : Int, npc_id~ : Int, selection~ : Int?)
  /// Forfeit one in-progress quest.
  ForfeitQuest(quest_id~ : Int)
} derive(Debug, ToJson, @json.FromJson)

///|
pub impl ClientMessage for QuestActionMessage with type_code() {
  ClientOpcode::QUEST_ACTION.int_value()
}

///|
/// Local-server SHOW_STATUS_INFO (quest exp gain) sync event.
pub(all) struct ShowStatusExpGainMessage {
  /// Whether gain popup uses white style.
  white : Bool
  /// EXP gain amount.
  gain : Int
  /// Whether chat-style display is enabled.
  in_chat : Bool
  /// Bonus EXP from event.
  bonus_event_exp : Int
  /// Third monster kill event bonus flag/value.
  third_monster_kill_event : Int
  /// Wedding bonus EXP.
  wedding_bonus : Int
  /// Quest bonus EXP rate when available.
  quest_bonus_rate : Int?
  /// Party bonus multiplier.
  party_bonus_multiplier : Int
  /// Party bonus EXP.
  party_bonus : Int
  /// Equipment bonus EXP.
  equip_bonus : Int
  /// Internet cafe bonus EXP.
  internet_cafe_bonus : Int
  /// Rainbow week bonus EXP.
  rainbow_week_bonus : Int
} derive(Debug, ToJson, @json.FromJson)

///|
pub impl ServerMessage for ShowStatusExpGainMessage with type_code() {
  Opcode::SHOW_STATUS_INFO.int_value()
}
