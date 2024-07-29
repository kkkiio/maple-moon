struct InPacket {
  bytes : Bytes
  pos : Int
}

pub fn InPacket::new(bytes : Bytes) -> InPacket {
  { bytes, pos: 0 }
}

pub fn read_ushort(self : InPacket) -> Int {
  self.read_int(size=2)
}

pub fn read_int(self : InPacket, ~size : Int = 4) -> Int {
  (0).until(size).fold(
    fn(acc, i) { acc + self.bytes[self.pos + i].to_int().lsl(8 * i) },
    init=0,
  )
}
