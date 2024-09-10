struct PingHandler {} derive(Default)

pub fn PingHandler::new() -> PingHandler {
  PingHandler::default()
}

pub fn handle(self : PingHandler, _packet : InPacket) -> Unit!Error {
  OutPacket::new(OutPacketOpcode::PONG).dispatch()
  if false {
    fail!("WORKAROUND: implement trait")
  }
}
