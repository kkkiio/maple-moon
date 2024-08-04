struct PacketProcessor {
  session : Session
}

fn PacketProcessor::new(
  handlers : @immut/hashmap.T[Opcode, PacketHandler]
) -> PacketProcessor {
  { session: Session::new(PacketSwitch::new(handlers)) }
}

struct Singleton[T] {
  mut instance : T?
}

pub fn Singleton::new[T]() -> Singleton[T] {
  { instance: None }
}

pub fn Singleton::set[T](self : Singleton[T], value : T) -> Unit {
  self.instance = Some(value)
}

pub fn must_get[T](self : Singleton[T]) -> T {
  self.instance.unwrap()
}

let g_packet_processor : Singleton[PacketProcessor] = Singleton::new()

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

pub fn reconnect_login(self : PacketProcessor) -> Unit {
  self.session.reconnect("/login")
}

pub fn connect_channel(self : PacketProcessor, channel : Int) -> Unit {
  self.session.connect("/channel/\(channel)")
}

pub fn get_status(self : PacketProcessor) -> ConnectionStatus {
  self.session.get_status()
}
