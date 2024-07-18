// Opcode: LOGIN_START(35)
struct LoginStartPacket {
  base : OutPacket
}

pub fn LoginStartPacket::new() -> OutPacket {
  OutPacket::new(OutPacketOpcode::LOGIN_START)
}
