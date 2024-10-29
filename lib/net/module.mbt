struct Module {
  processor : PacketProcessor
}

pub fn Module::new(
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> Module {
  let processor = PacketProcessor::new(handlers.add(PING, handle_ping))
  g_packet_processor.set(processor)
  { processor, }
}

pub fn handle_ping(_packet : InPacket) -> Unit {
  OutPacket::new(OutPacketOpcode::PONG).dispatch()
}

pub fn process_in(self : Module) -> Unit {
  self.processor.process_in()
}
