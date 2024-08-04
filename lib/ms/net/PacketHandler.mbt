pub trait PacketHandler {
  handle(Self, InPacket) -> Unit!Error
}
