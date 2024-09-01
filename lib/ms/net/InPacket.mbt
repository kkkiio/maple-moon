struct InPacket {
  bytes : Bytes
  mut pos : Int
}

pub fn InPacket::new(bytes : Bytes) -> InPacket {
  { bytes, pos: 0 }
}

pub fn available(self : InPacket) -> Bool {
  self.pos < self.bytes.length()
}

pub fn check_size(self : InPacket, size : Int) -> Unit!ReadPacketError {
  if self.pos + size > self.bytes.length() {
    raise ReadPacketError("Out of range")
  }
}

pub fn read_ubyte(self : InPacket) -> Int!ReadPacketError {
  self.check_size!(1)
  let res = self.bytes[self.pos]
  self.pos += 1
  res.to_int()
}

pub fn read_byte(self : InPacket) -> Int!ReadPacketError {
  let u = self.read_ubyte!()
  if u > 0x7f {
    u - 0x100
  } else {
    u
  }
}

pub fn read_bool(self : InPacket) -> Bool!ReadPacketError {
  self.read_byte!() != 0
}

pub fn read_ushort(self : InPacket) -> Int!ReadPacketError {
  self.check_size!(2)
  let res = read_le_uint16(self.bytes, self.pos)
  self.pos += 2
  res.to_int()
}

pub fn read_short(self : InPacket) -> Int!ReadPacketError {
  let u = self.read_ushort!()
  if u > 0x7fff {
    u - 0x10000
  } else {
    u
  }
}

pub fn read_uint(self : InPacket) -> UInt!ReadPacketError {
  self.check_size!(4)
  let res = read_le_uint32(self.bytes, self.pos)
  self.pos += 4
  res
}

pub fn read_int(self : InPacket) -> Int!ReadPacketError {
  self.read_uint!().to_int()
}

pub fn read_long(self : InPacket) -> Int64!ReadPacketError {
  self.check_size!(8)
  let res = read_le_uint64(self.bytes, self.pos)
  self.pos += 8
  res.to_int64()
}

pub fn read_string(self : InPacket) -> String!ReadPacketError {
  let size = self.read_ushort!()
  self.check_size!(size)
  let res = byte_iter_to_string(
    self.pos.until(self.pos + size).map(fn(i) { self.bytes[i] }),
    size,
  )
  self.pos += size
  res
}

pub fn read_padded_string(
  self : InPacket,
  size : Int
) -> String!ReadPacketError {
  self.check_size!(size)
  let res = byte_iter_to_string(
    self.pos
    .until(self.pos + size)
    .map(fn(i) { self.bytes[i] })
    .take_while(fn(b) { b.to_int() != 0 }),
    size,
  )
  self.pos += size
  res
}

fn byte_iter_to_string(byte_iter : Iter[Byte], max_size : Int) -> String {
  let buf = Buffer::new(size_hint=max_size)
  // TODO: support more charset
  byte_iter.each(fn(b) { buf.write_char(Char::from_int(b.to_int())) })
  buf.to_string()
}

pub fn skip(self : InPacket, size : Int) -> Unit!ReadPacketError {
  self.check_size!(size)
  self.pos += size
}

pub fn skip_byte(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(1)
}

pub fn skip_short(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(2)
}

pub fn skip_int(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(4)
}

pub fn skip_long(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(8)
}

fn read_le_uint16(bytes : Bytes, offset : Int) -> UInt {
  bytes[offset].to_uint() + bytes[offset + 1].to_uint().lsl(8)
}

fn read_le_uint32(bytes : Bytes, offset : Int) -> UInt {
  bytes[offset].to_uint() +
  bytes[offset + 1].to_uint().lsl(8) +
  bytes[offset + 2].to_uint().lsl(16) +
  bytes[offset + 3].to_uint().lsl(24)
}

fn read_le_uint64(bytes : Bytes, offset : Int) -> UInt64 {
  bytes[offset].to_uint().to_uint64() +
  bytes[offset + 1].to_uint().to_uint64().lsl(8) +
  bytes[offset + 2].to_uint().to_uint64().lsl(16) +
  bytes[offset + 3].to_uint().to_uint64().lsl(24) +
  bytes[offset + 4].to_uint().to_uint64().lsl(32) +
  bytes[offset + 5].to_uint().to_uint64().lsl(40) +
  bytes[offset + 6].to_uint().to_uint64().lsl(48) +
  bytes[offset + 7].to_uint().to_uint64().lsl(56)
}

pub type! ReadPacketError String

pub impl Show for ReadPacketError with output(self, logger) {
  match self {
    ReadPacketError(err) => logger.write_string(err)
  }
}
