/// Messages for NPC interactions.

///|
/// Ask server to start NPC dialogue.
pub(all) struct TalkToNpcMessage {
  oid : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for TalkToNpcMessage with type_code() {
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
pub impl ClientMessage for NpcTalkMoreMessage with type_code() {
  ClientOpcode::NPC_TALK_MORE.int_value()
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
pub impl ServerMessage for NpcSpawnMessage with type_code() {
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
pub impl ServerMessage for NpcSpawnControllerMessage with type_code() {
  Opcode::SPAWN_NPC_C.int_value()
}
