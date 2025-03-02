///| Parses key mappings and sends them to the keyboard
pub fn parse_keymap(recv : @net.InPacket) -> Array[(Int, Int)]! {
  // Skip first byte
  recv.skip!(1)

  // Read 90 key mappings
  let mappings = Array::new()
  for i in 0..<90 {
    let kind = recv.read_ubyte!()
    let action = recv.read_int!()
    mappings.push((kind, action))
  }
  mappings
}

///| Requests the server to change key mappings
struct ChangeKeymapMessage {
  updated_actions : Array[(MsKey, Mapping?)]
} derive(Show)

///|
pub fn ChangeKeymapMessage::new(
  updated_actions : Array[(MsKey, Mapping?)]
) -> ChangeKeymapMessage {
  { updated_actions, }
}

///|
pub impl @net.OutMessage for ChangeKeymapMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::CHANGE_KEYMAP)
  packet.write_int(0) // mode
  packet.write_int(self.updated_actions.length()) // Number of key changes
  for v in self.updated_actions {
    packet.write_int(v.0.int_value()) // key
    packet.write_byte(v.1.map_or(0, fn(it) { it.t.int_value() }).to_byte()) // type
    packet.write_int(v.1.map_or(0, fn(it) { it.action })) // action
  }
  packet
}
