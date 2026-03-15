///|
priv enum QuestActionMessage {
  // Restore a lost item for a quest.
  RestoreLostItem(quest_id~ : Int, item_id~ : Int)
  // Start a quest when talking to an NPC.
  StartQuest(quest_id~ : Int, npc_id~ : Int)
  // Complete a quest when talking to an NPC, optionally with a selection.
  CompleteQuest(quest_id~ : Int, npc_id~ : Int, selection~ : Int?)
  // Forfeit an active quest.
  ForfeitQuest(quest_id~ : Int)
  // Start a quest via a script (e.g., item-triggered or event-triggered).
  ScriptedStartQuest(quest_id~ : Int, npc_id~ : Int)
  // Complete a quest via a script.
  ScriptedEndQuest(quest_id~ : Int, npc_id~ : Int)
} derive(Show)
