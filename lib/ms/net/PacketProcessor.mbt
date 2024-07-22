struct PacketProcessor {
  session : Session
}

fn PacketProcessor::new() -> PacketProcessor {
  { session: Session::new(PacketSwitch::new()) }
}

let g_packet_processor : PacketProcessor = PacketProcessor::new()

pub fn PacketProcessor::get() -> PacketProcessor {
  g_packet_processor
}

pub fn initialize(self : PacketProcessor) -> Unit {
  g_packet_processor.session.initialize()
}

pub fn process_out(self : PacketProcessor, data : Bytes) -> Unit {
  self.session.write(data)
}

pub fn process_in(self : PacketProcessor) -> Unit {
  self.session.read()
}

pub fn reconnect_login(self : PacketProcessor) -> Unit {
  g_packet_processor.session.reconnect_login()
}

pub fn connect_channel(self : PacketProcessor, channel : Int) -> Unit {
  g_packet_processor.session.connect_channel(channel)
}

// pub fn is_connected(self : PacketProcessor) -> Bool {
//   g_packet_processor.session.is_connected()
// }
