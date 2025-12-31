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
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for MoveMonsterMessage with type_code() {
  @net.ClientOpcode::MOVE_MONSTER.int_value()
}

///|
pub impl @net.OutMessage for MoveMonsterMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::MOVE_MONSTER)
  packet.write_int(self.oid)
  packet.write_short(self.move_id)
  packet.write_byte(self.nibbles.to_byte())
  packet.write_byte(self.action.to_byte())
  packet.write_byte(self.skill.to_byte())
  packet.write_byte(self.skill_level.to_byte())
  packet.write_short(self.option)
  packet.skip(13)
  packet.write_point(self.start_pos)
  packet.write_byte((1).to_byte())
  @physics.write_movement(packet, self.movement)
  packet
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
pub impl ServerMessage for MobSpawnMessage with type_code() {
  @net.Opcode::SPAWN_MOB.int_value()
}

///|

///|
pub(all) struct MobDamageMessage {
  oid : Int
  damage : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for MobDamageMessage with type_code() {
  @net.ClientOpcode::CLOSE_ATTACK.int_value()
}

///|
pub(all) struct MobHpMessage {
  oid : Int
  percent : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for MobHpMessage with type_code() {
  @net.Opcode::SHOW_MOB_HP.int_value()
}

///|
pub(all) struct KillMobMessage {
  oid : Int
  animation : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for KillMobMessage with type_code() {
  @net.Opcode::KILL_MOB.int_value()
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
pub impl ServerMessage for MobSpawnControllerMessage with type_code() {
  @net.Opcode::SPAWN_MOB_C.int_value()
}

///|
using @struct {type Point}

///|
using @physics {type Movement}
