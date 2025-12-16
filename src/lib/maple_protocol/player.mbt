///|
fn new_move_player_packet(movement : Movement) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::MOVE_PLAYER)
  packet.skip(9)
  packet.write_byte((1).to_byte())
  write_movement(packet, movement)
  packet
}

///|
fn write_movement(out : @net.OutPacket, movement : @physics.Movement) -> Unit {
  out.write_byte(movement.command.to_byte())
  out.write_short(movement.xpos)
  out.write_short(movement.ypos)
  out.write_short(movement.lastx)
  out.write_short(movement.lasty)
  out.write_short(movement.fh)
  out.write_byte(movement.newstate.to_byte())
  out.write_short(movement.duration)
}
