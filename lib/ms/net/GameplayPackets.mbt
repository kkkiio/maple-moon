// Opcode: CHANGE_MAP(38)
struct ChangeMapPacket {
  base : OutPacket
  died : Bool
  targetid : Int
  targetp : String
  usewheel : Bool
}

pub fn ChangeMapPacket::new(
  died : Bool,
  targetid : Int,
  targetp : String,
  usewheel : Bool
) -> ChangeMapPacket {
  {
    base: OutPacket::new(OutPacketOpcode::CHANGE_MAP),
    died,
    targetid,
    targetp,
    usewheel,
  }
}

pub fn dispatch(self : ChangeMapPacket) -> Unit {
  self.base.dispatch()
}

// Opcode: PLAYER_MAP_TRANSFER(207)
struct PlayerMapTransferPacket {
  base : OutPacket
}

pub fn PlayerMapTransferPacket::new() -> PlayerMapTransferPacket {
  { base: OutPacket::new(OutPacketOpcode::PLAYER_MAP_TRANSFER) }
}

pub fn dispatch(self : PlayerMapTransferPacket) -> Unit {
  self.base.dispatch()
}
