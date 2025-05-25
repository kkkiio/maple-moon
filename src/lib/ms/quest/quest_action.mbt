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

///|
impl @net.OutMessage for QuestActionMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::QUEST_ACTION)
  match self {
    QuestActionMessage::RestoreLostItem(quest_id~, item_id~) => {
      packet.write_byte(0)
      packet.write_short(quest_id)
      packet.write_int(0) // unknonw int
      packet.write_int(item_id)
    }
    QuestActionMessage::StartQuest(quest_id~, npc_id~) => {
      packet.write_byte(1)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
    QuestActionMessage::CompleteQuest(quest_id~, npc_id~, selection~) => {
      packet.write_byte(2)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
      if selection is Some(selection) {
        packet.write_short(selection)
      }
    }
    QuestActionMessage::ForfeitQuest(quest_id~) => {
      packet.write_byte(3)
      packet.write_short(quest_id)
    }
    QuestActionMessage::ScriptedStartQuest(quest_id~, npc_id~) => {
      packet.write_byte(4)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
    QuestActionMessage::ScriptedEndQuest(quest_id~, npc_id~) => {
      packet.write_byte(5)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
  }
  packet
}
