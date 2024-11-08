struct PacketProcessor {
  session : Session
}

fn PacketProcessor::new(
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> PacketProcessor {
  let switch = PacketSwitch::new(handlers)
  { session: Session::new(fn(it) { switch.forward(it) }) }
}

let g_packet_processor : @utils.Singleton[PacketProcessor] = @utils.Singleton::new()

pub fn PacketProcessor::get() -> PacketProcessor {
  g_packet_processor.must_get()
}

pub fn process_out(self : PacketProcessor, data : Bytes) -> Unit {
  self.session.write(data)
}

fn process_in(self : PacketProcessor) -> Unit {
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

struct PacketSwitch {
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
}

pub fn PacketSwitch::new(
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> PacketSwitch {
  { handlers, }
}

pub fn forward(self : PacketSwitch, bytes : Bytes) -> Unit {
  // Wrap the bytes with a parser
  let recv = InPacket::new(bytes)

  // Read the opcode to determine handler responsible
  let opcode = try {
    Opcode::from_int!(recv.read_ushort!())
  } catch {
    UnknownOpCodeError(opcode) => {
      @log.warn({ "opcode": opcode }, "unknown opcode")
      return
    }
    err => {
      @log.warn({ "blen": bytes.length(), "err": err }, "read opcode failed")
      return
    }
  }
  match self.handlers[opcode] {
    Some(handler) => handler(recv)
    None => @log.warn({ "opcode": opcode }, "Unhandled packet detected")
  }
}

pub fn with_log(
  opcode : Opcode,
  handler : (InPacket) -> Unit!,
  ~log_recv : Bool = true
) -> (InPacket) -> Unit {
  fn(recv : InPacket) {
    if log_recv {
      @log.debug(
        { "opcode": opcode, "len": recv.bytes.length() - recv.pos },
        "received",
      )
    }
    try {
      handler!(recv)
    } catch {
      err =>
        @log.error({ "opcode": opcode, "err": err }, "handle packet failed")
    }
  }
}
