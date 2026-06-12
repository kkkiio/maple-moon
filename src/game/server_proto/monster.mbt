/// Messages for monsters activities.

///|
/// Message for moving a monster
pub(all) struct MoveMonsterMessage {
  oid : Int
  move_id : Int
  nibbles : Int
  action : Int
  skill : Int
  skill_level : Int
  option : Int
  start_pos : Point[Int]
  movement : Movement
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for MoveMonsterMessage with fn type_code() {
  ClientOpcode::MOVE_MONSTER.int_value()
}

///|
pub(all) struct MobSpawnMessage {
  oid : Int
  id : Int
  x : Int
  y : Int
  stance : Int
  fh : Int
  team : Int
} derive(ToJson, @json.FromJson)

///|
pub impl ServerMessage for MobSpawnMessage with fn type_code() {
  Opcode::SPAWN_MOB.int_value()
}

///|

///|
pub(all) struct MobDamageMessage {
  oid : Int
  damage : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for MobDamageMessage with fn type_code() {
  ClientOpcode::CLOSE_ATTACK.int_value()
}

///|
pub(all) struct MobHpMessage {
  oid : Int
  percent : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for MobHpMessage with fn type_code() {
  Opcode::SHOW_MOB_HP.int_value()
}

///|
pub(all) struct KillMobMessage {
  oid : Int
  animation : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for KillMobMessage with fn type_code() {
  Opcode::KILL_MOB.int_value()
}

///|
pub(all) struct MobSpawnControllerMessage {
  mode : Int
  oid : Int
  id : Int
  x : Int
  y : Int
  stance : Int
  fh : Int
  team : Int
} derive(ToJson, @json.FromJson)

///|
pub impl ServerMessage for MobSpawnControllerMessage with fn type_code() {
  Opcode::SPAWN_MOB_C.int_value()
}

///|
using @struct {type Point}

///|
using @physics {type Movement}
