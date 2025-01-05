///|
struct PacketProcessor {
  session : Session
  switch : PacketSwitch
}

///|
pub fn PacketProcessor::init() -> PacketProcessor {
  let processor = PacketProcessor::new()
  g_packet_processor.set(processor)
  processor
}

///|
fn PacketProcessor::new() -> PacketProcessor {
  let switch = PacketSwitch::new()
  { session: Session::new(fn(it) { switch.forward(it) }), switch }
}

///|
let g_packet_processor : @utils.Singleton[PacketProcessor] = @utils.Singleton::new()

///|
pub fn PacketProcessor::get() -> PacketProcessor {
  g_packet_processor.must_get()
}

///|
pub fn reset_handlers(
  self : PacketProcessor,
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> Unit {
  self.switch.reset_handlers(handlers.add(PING, fn(_v) { handle_ping(self) }))
}

///|
pub fn process_out(self : PacketProcessor, data : Bytes) -> Unit {
  self.session.write(data)
}

///| send packet to the server
/// @alert deprecated "use send_message instead"
pub fn send_packet(self : PacketProcessor, packet : OutPacket) -> Unit {
  @log.log(
    packet.opcode.log_level(),
    { "opcode": packet.opcode },
    "sending packet",
  )
  self.process_out(packet.encode())
}

///| send message to the server
pub fn send_message[T : OutMessage](
  self : PacketProcessor,
  message : T,
  log_level~ : @log.Level = @log.Level::INFO,
  loc~ : SourceLoc = _
) -> Unit {
  @log.log(
    log_level,
    { "message": message.to_string() },
    "sending packet",
    loc~,
  )
  self.process_out(message.pack().encode())
}

///|
pub fn process_in(self : PacketProcessor) -> Unit {
  self.session.read()
}

///|
pub fn connect_login(self : PacketProcessor) -> Unit {
  self.session.connect("/login")
}

///|
pub fn connect_channel(self : PacketProcessor, channel : Int) -> Unit {
  self.session.close()
  self.session.connect("/channel/\{channel}")
}

///|
pub fn get_status(self : PacketProcessor) -> ConnectionStatus {
  self.session.get_status()
}

///|
struct PacketSwitch {
  mut handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
}

///|
pub fn PacketSwitch::new() -> PacketSwitch {
  { handlers: @immut/hashmap.new() }
}

///|
pub fn reset_handlers(
  self : PacketSwitch,
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> Unit {
  self.handlers = handlers
}

///|
pub fn forward(self : PacketSwitch, bytes : Bytes) -> Unit {
  // Wrap the bytes with a parser
  let recv = InPacket::new(bytes)

  // Read the opcode to determine handler responsible
  let opcode = try {
    Opcode::from_int!(recv.read_ushort!())
  } catch {
    UnknownOpCodeError(opcode) => {
      @log.warn(
        { "opcode": @utils.to_hex_string(opcode.reinterpret_as_uint()) },
        "unknown opcode",
      )
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

///|
pub fn with_log(
  opcode : Opcode,
  handler : (InPacket) -> Unit!,
  log_recv~ : Bool = false
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

///|
pub fn make_handler[T : Show](
  opcode : Opcode,
  parser : (InPacket) -> T!,
  handler : (T) -> Unit,
  log_recv~ : Bool = false,
  loc~ : SourceLoc = _
) -> (Opcode, (InPacket) -> Unit) {
  (
    opcode,
    fn(recv) {
      let message = try {
        parser!(recv)
      } catch {
        err => {
          @log.error(
            { "op": opcode, "err": err, "raw_body": recv.bytes },
            "parse packet failed",
            loc~,
          )
          return
        }
      }
      if log_recv {
        @log.debug({ "op": opcode, "body": message }, "received", loc~)
      }
      handler(message)
    },
  )
}

///|
pub fn handle_ping(processor : PacketProcessor) -> Unit {
  processor.send_message(PongMessage::default(), log_level=@log.Level::DEBUG)
}

///|
struct PongMessage {} derive(Default, Show)

///|
impl OutMessage for PongMessage with pack(self) {
  ignore(self)
  OutPacket::new(OutPacketOpcode::PONG)
}
