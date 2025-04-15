///| A packet to be sent to the server
struct OutPacket {
  buf : @buffer.T
  opcode : OutPacketOpcode
}

///|
pub fn OutPacket::new(opcode : OutPacketOpcode) -> OutPacket {
  let pkt = { buf: @buffer.new(), opcode }
  pkt.write_short(opcode.int_value())
  pkt
}

///|
pub fn dispatch(self : OutPacket) -> Unit {
  Network::get().send_packet(self)
}

///|
pub fn encode(self : OutPacket) -> Bytes {
  self.buf.to_bytes()
}

///|
pub fn OutPacket::skip(self : OutPacket, count : Int) -> Unit {
  let mut i = 0
  while i < count {
    self.buf.write_byte(b'\x00')
    i += 1
  }
}

///|
pub fn OutPacket::write_byte(self : OutPacket, ch : Byte) -> Unit {
  self.buf.write_byte(ch)
}

///|
pub fn OutPacket::write_short(self : OutPacket, sh : Int) -> Unit {
  let mut i = 0
  let mut sh = sh
  while i < 2 {
    self.write_byte(sh.land(0xFF).to_byte())
    sh = sh >> 8
    i += 1
  }
}

///|
pub fn write_int(self : OutPacket, in_val : Int) -> Unit {
  let mut i = 0
  let mut in_val = in_val
  while i < 4 {
    self.write_byte(in_val.land(0xFF).to_byte())
    in_val = in_val >> 8
    i += 1
  }
}

///|
pub fn OutPacket::write_long(self : OutPacket, lg : Int64) -> Unit {
  let mut i = 0
  let mut lg = lg
  while i < 8 {
    self.write_byte(lg.land(0xFFL).to_byte())
    lg = lg >> 8
    i += 1
  }
}

///|
pub fn OutPacket::write_time(self : OutPacket) -> Unit {
  // NOTE: server doesn't seem to care about the value
  self.write_int(0)
}

///|
pub fn OutPacket::write_point(
  self : OutPacket,
  position : @struct.Point[Int]
) -> Unit {
  self.write_short(position.x)
  self.write_short(position.y)
}

///|
pub fn OutPacket::write_string(self : OutPacket, str : String) -> Unit {
  self.write_short(str.length())
  buf_write_utf8(self.buf, str)
}

///|
pub fn buf_write_utf8(buf : @buffer.T, str : String) -> Unit {
  let bytes = FixedArray::make(4, b'\x00')
  str
  .iter()
  .each(fn(c) {
    let len = bytes.set_utf8_char(0, c)
    for i = 0; i < len; i = i + 1 {
      buf.write_byte(bytes[i])
    }
  })
}

// pub fn OutPacket::write_random(self : OutPacket) -> Unit {
//   let randomizer = @basic.Randomizer::default()
//   let rand = randomizer.next_int(Int::max_value())
// self.write_int(rand)
// }

///|
pub fn OutPacket::write_hardware_info(self : OutPacket) -> Unit {
  let macs = @config.global().get_macs()
  let hwid = @config.global().get_hwid()
  self.write_string(macs)
  self.write_string(hwid)
}

///| Message to be sent to the server
pub(open) trait OutMessage: Show {
  pack(Self) -> OutPacket
}

///|
pub fn hex_to_dec(hex_val : String) -> Byte!@strconv.StrConvError {
  @strconv.parse_int!(hex_val, base=16).to_byte()
}

///| Opcodes for OutPackets associated with version 83 of the game
pub(all) enum OutPacketOpcode {
  LOGIN
  CHAR_LIST_REQUEST
  SERVER_STATUS_REQUEST
  ACCEPT_TOS
  SET_GENDER
  SERVERLIST_REQUEST
  SELECT_CHAR
  PLAYER_LOGIN
  NAME_CHAR
  CREATE_CHAR
  DELETE_CHAR
  PONG
  REGISTER_PIC
  SELECT_CHAR_PIC
  LOGIN_START
  CHANGE_MAP
  CHANGE_CHANNEL
  ENTER_CASHSHOP
  MOVE_PLAYER
  CLOSE_ATTACK
  RANGED_ATTACK
  MAGIC_ATTACK
  TAKE_DAMAGE
  GENERAL_CHAT
  TALK_TO_NPC
  NPC_TALK_MORE
  NPC_SHOP_ACTION
  GIVE_FAME
  CHAR_INFO_REQUEST
  GATHER_ITEMS
  SORT_ITEMS
  MOVE_ITEM
  USE_ITEM
  SCROLL_EQUIP
  DROP_MESOS
  SPEND_AP
  HEAL_OVER_TIME
  SPEND_SP
  CHANGE_KEYMAP
  USE_SKILL
  PLAYER_INTERACTION
  PARTY_OPERATION
  ADMIN_COMMAND
  MOVE_MONSTER
  PICKUP_ITEM
  DAMAGE_REACTOR
  PLAYER_MAP_TRANSFER
  PLAYER_UPDATE
} derive(Eq, Compare, Show)

///|
pub fn int_value(self : OutPacketOpcode) -> Int {
  match self {
    LOGIN => 1
    CHAR_LIST_REQUEST => 5
    SERVER_STATUS_REQUEST => 6
    ACCEPT_TOS => 7
    SET_GENDER => 8
    SERVERLIST_REQUEST => 11
    SELECT_CHAR => 19
    PLAYER_LOGIN => 20
    NAME_CHAR => 21
    CREATE_CHAR => 22
    DELETE_CHAR => 23
    PONG => 24
    REGISTER_PIC => 29
    SELECT_CHAR_PIC => 30
    LOGIN_START => 35
    CHANGE_MAP => 38
    CHANGE_CHANNEL => 39
    ENTER_CASHSHOP => 40
    MOVE_PLAYER => 41
    CLOSE_ATTACK => 44
    RANGED_ATTACK => 45
    MAGIC_ATTACK => 46
    TAKE_DAMAGE => 48
    GENERAL_CHAT => 49
    TALK_TO_NPC => 58
    NPC_TALK_MORE => 60
    NPC_SHOP_ACTION => 61
    GIVE_FAME => 95
    CHAR_INFO_REQUEST => 97
    GATHER_ITEMS => 69
    SORT_ITEMS => 70
    MOVE_ITEM => 71
    USE_ITEM => 72
    SCROLL_EQUIP => 86
    DROP_MESOS => 94
    SPEND_AP => 87
    HEAL_OVER_TIME => 89
    SPEND_SP => 90
    CHANGE_KEYMAP => 135
    USE_SKILL => 91
    PLAYER_INTERACTION => 123
    PARTY_OPERATION => 124
    ADMIN_COMMAND => 128
    MOVE_MONSTER => 188
    PICKUP_ITEM => 202
    DAMAGE_REACTOR => 205
    PLAYER_MAP_TRANSFER => 207
    PLAYER_UPDATE => 223
  }
}

///|
pub fn log_level(self : OutPacketOpcode) -> @log.Level {
  match self {
    MOVE_PLAYER | MOVE_MONSTER => @log.Level::TRACE
    _ => @log.Level::INFO
  }
}
