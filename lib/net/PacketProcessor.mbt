struct PacketProcessor {
  session : Session
}

fn PacketProcessor::new(
  handlers : @immut/hashmap.T[Opcode, PacketHandler]
) -> PacketProcessor {
  let switch = PacketSwitch::new(handlers)
  { session: Session::new(fn(it) { switch.forward(it) }) }
}

let g_packet_processor : @utils.Singleton[PacketProcessor] = @utils.Singleton::new()

pub fn PacketProcessor::get() -> PacketProcessor {
  g_packet_processor.must_get()
}

pub fn PacketProcessor::initialize(
  handlers : @immut/hashmap.T[Opcode, PacketHandler]
) -> Unit {
  g_packet_processor.set(PacketProcessor::new(handlers))
}

pub fn process_out(self : PacketProcessor, data : Bytes) -> Unit {
  self.session.write(data)
}

pub fn process_in(self : PacketProcessor) -> Unit {
  self.session.read()
}

pub fn connect_login(self : PacketProcessor) -> Unit {
  self.session.connect("/login")
}

pub fn connect_channel(self : PacketProcessor, channel : Int) -> Unit {
  self.session.close()
  self.session.connect("/channel/\{channel}")
}

pub fn get_status(self : PacketProcessor) -> ConnectionStatus {
  self.session.get_status()
}
