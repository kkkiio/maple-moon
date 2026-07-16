/// Messages for NPC interactions.

///|
/// Ask server to start NPC dialogue.
pub(all) struct TalkToNpcMessage {
  oid : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for TalkToNpcMessage with fn type_code() {
  ClientOpcode::TALK_TO_NPC.int_value()
}

///|
/// Continue/respond current NPC dialogue.
pub(all) struct NpcTalkMoreMessage {
  lastmsg : Int
  response : Int
  selection : Int?
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for NpcTalkMoreMessage with fn type_code() {
  ClientOpcode::NPC_TALK_MORE.int_value()
}

///|
/// Open or replace the current NPC dialogue view.
pub(all) struct NpcDialogueMessage {
  /// Template ID used for the speaker portrait and name.
  npcid : Int
  /// Stable `TalkType::int_value` understood by the Maple Moon client.
  talk_type : Int
  /// Numeric speaker placement and ownership value.
  speaker : Int
  /// MapleStory markup text rendered in the dialogue body.
  text : String
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for NpcDialogueMessage with fn type_code() {
  Opcode::NPC_DIALOGUE.int_value()
}

///|
/// Spawn a NPC without controller ownership.
pub(all) struct NpcSpawnMessage {
  oid : Int
  id : Int
  x : Int
  y : Int
  flip : Bool
  fh : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for NpcSpawnMessage with fn type_code() {
  Opcode::SPAWN_NPC.int_value()
}

///|
/// Spawn/remove a NPC with controller mode.
pub(all) struct NpcSpawnControllerMessage {
  mode : Int
  oid : Int
  id : Int
  x : Int
  y : Int
  flip : Bool
  fh : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for NpcSpawnControllerMessage with fn type_code() {
  Opcode::SPAWN_NPC_C.int_value()
}
