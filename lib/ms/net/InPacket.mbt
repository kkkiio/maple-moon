struct InPacket {
  bytes : Bytes
  mut pos : Int
}

pub fn InPacket::new(bytes : Bytes) -> InPacket {
  { bytes, pos: 0 }
}

pub fn read_int(self : InPacket, ~size : Int = 4) -> Int!Error {
  if self.pos + size > self.bytes.length() {
    fail!("Out of bounds reading packet")
  }
  let res = (0).until(size).fold(
    fn(acc, i) { acc + self.bytes[self.pos + i].to_int().lsl(8 * i) },
    init=0,
  )
  self.pos += size
  res
}

pub fn read_byte(self : InPacket) -> Int!Error {
  self.read_int!(size=1)
}

pub fn read_bool(self : InPacket) -> Bool!Error {
  self.read_int!(size=1) != 0
}

pub fn read_ushort(self : InPacket) -> Int!Error {
  self.read_int!(size=2)
}

pub fn read_string(self : InPacket) -> String!Error {
  let len = self.read_int!(size=2)
  self.read_string_by_length!(len)
}

fn read_string_by_length(self : InPacket, len : Int) -> String!Error {
  if self.pos + len > self.bytes.length() {
    fail!("Out of bounds reading packet")
  }
  let buf = Buffer::new(size_hint=len)
  for i = 0; i < len; i = i + 1 {
    let b = self.bytes[self.pos]
    if b != b'\x00' {
      buf.write_char(Char::from_int(b.to_int()))
    }
    self.pos += 1
  }
  buf.to_string()
}

pub fn skip(self : InPacket, size : Int) -> Unit!Error {
  let next = self.pos + size
  if next > self.bytes.length() {
    fail!("Out of bounds reading packet")
  }
  self.pos = next
}

pub fn skip_byte(self : InPacket) -> Unit!Error {
  self.skip!(1)
}

pub fn skip_short(self : InPacket) -> Unit!Error {
  self.skip!(2)
}

pub fn skip_int(self : InPacket) -> Unit!Error {
  self.skip!(4)
}

pub fn skip_long(self : InPacket) -> Unit!Error {
  self.skip!(8)
}
