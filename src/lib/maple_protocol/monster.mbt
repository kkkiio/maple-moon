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
using @struct {type Point}

///|
using @physics {type Movement}
