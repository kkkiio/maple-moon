///|
struct Network {
  session : Session
  switch : PacketSwitch
}

///|
pub fn Network::init() -> Network {
  let processor = Network::new()
  g_network.set(processor)
  processor
}

///|
pub fn Network::new() -> Network {
  let switch = PacketSwitch::new()
  { session: Session::new(fn(it) { switch.forward(it) }), switch }
}

///|
let g_network : @utils.Singleton[Network] = @utils.Singleton::new()

///|
pub fn Network::get() -> Network {
  g_network.must_get()
}

///|
pub fn reset_handlers(
  self : Network,
  handlers : @immut/hashmap.T[Opcode, (InPacket) -> Unit]
) -> Unit {
  self.switch.reset_handlers(handlers.add(PING, fn(_v) { handle_ping(self) }))
}

///|
pub fn process_out(self : Network, data : Bytes) -> Unit {
  self.session.write(data)
}

///| send packet to the server
/// @alert deprecated "use send_message instead"
pub fn send_packet(self : Network, packet : OutPacket) -> Unit {
  @log.log(
    packet.opcode.log_level(),
    { "opcode": packet.opcode },
    "sending packet",
  )
  self.process_out(packet.encode())
}

///| send message to the server
pub fn send_message[T : OutMessage](
  self : Network,
  message : T,
  log_level~ : @log.Level = @log.Level::DEBUG,
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
pub fn process_in(self : Network) -> Unit {
  self.session.read()
}

///|
pub fn connect_login(self : Network) -> Unit {
  self.session.connect("/login")
}

///|
pub fn connect_channel(self : Network, channel : Int) -> Unit {
  self.session.close()
  self.session.connect("/channel/\{channel}")
}

///|
pub fn Network::close(self : Network) -> Unit {
  self.session.close()
}

///|
pub fn get_status(self : Network) -> ConnectionStatus {
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
pub fn PacketSwitch::reset_handlers(
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
  match self.handlers.get(opcode) {
    Some(handler) => handler(recv)
    None => @log.warn({ "opcode": opcode }, "Unhandled packet detected")
  }
}

///| @alert deprecated "use make_handler instead"
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
pub fn handle_ping(processor : Network) -> Unit {
  processor.send_message(PongMessage::default(), log_level=@log.Level::DEBUG)
}

///|
priv struct PongMessage {} derive(Default, Show)

///|
impl OutMessage for PongMessage with pack(self) {
  ignore(self)
  OutPacket::new(ClientOpcode::PONG)
}
