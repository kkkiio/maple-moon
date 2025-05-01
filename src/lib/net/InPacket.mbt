///|
struct InPacket {
  bytes : Bytes
  mut pos : Int
}

///|
pub fn InPacket::new(bytes : Bytes) -> InPacket {
  { bytes, pos: 0 }
}

///|
pub fn available(self : InPacket) -> Bool {
  self.pos < self.bytes.length()
}

///|
pub fn check_available(self : InPacket, size : Int) -> Unit!ReadPacketError {
  if self.pos + size > self.bytes.length() {
    raise ReadPacketError("Out of range")
  }
}

///|
pub fn check_finished(self : InPacket) -> Unit!ReadPacketError {
  if self.pos < self.bytes.length() {
    raise ReadPacketError("Remaining \{self.bytes.length() - self.pos} bytes")
  }
}

///|
pub fn read_ubyte(self : InPacket) -> Int!ReadPacketError {
  self.check_available!(1)
  let res = self.bytes[self.pos]
  self.pos += 1
  res.to_int()
}

///|
pub fn read_byte(self : InPacket) -> Int!ReadPacketError {
  let u = self.read_ubyte!()
  if u > 0x7f {
    u - 0x100
  } else {
    u
  }
}

///|
pub fn read_bool(self : InPacket) -> Bool!ReadPacketError {
  match self.read_byte!() {
    0 => false
    1 => true
    b => raise ReadPacketError("Invalid bool value=\{b}")
  }
}

///|
pub fn read_ushort(self : InPacket) -> Int!ReadPacketError {
  self.check_available!(2)
  let res = read_le_uint16(self.bytes, self.pos)
  self.pos += 2
  res.reinterpret_as_int()
}

///|
pub fn read_short(self : InPacket) -> Int!ReadPacketError {
  let u = self.read_ushort!()
  if u > 0x7fff {
    u - 0x10000
  } else {
    u
  }
}

///|
pub fn read_uint(self : InPacket) -> UInt!ReadPacketError {
  self.check_available!(4)
  let res = read_le_uint32(self.bytes, self.pos)
  self.pos += 4
  res
}

///|
pub fn read_int(self : InPacket) -> Int!ReadPacketError {
  self.read_uint!().reinterpret_as_int()
}

///|
pub fn read_long(self : InPacket) -> Int64!ReadPacketError {
  self.check_available!(8)
  let res = read_le_uint64(self.bytes, self.pos)
  self.pos += 8
  res.reinterpret_as_int64()
}

///|
pub fn read_string(self : InPacket) -> String!ReadPacketError {
  let size = self.read_ushort!()
  self.check_available!(size)
  let res = byte_iter_to_string(
    self.pos.until(self.pos + size).map(fn(i) { self.bytes[i] }),
    size,
  )
  self.pos += size
  res
}

///|
pub fn read_padded_string(
  self : InPacket,
  size : Int
) -> String!ReadPacketError {
  self.check_available!(size)
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

///|
fn byte_iter_to_string(byte_iter : Iter[Byte], max_size : Int) -> String {
  let buf = StringBuilder::new(size_hint=max_size)
  // TODO: support more charset
  byte_iter.each(fn(b) { buf.write_char(Char::from_int(b.to_int())) })
  buf.to_string()
}

///|
pub fn skip(self : InPacket, size : Int) -> Unit!ReadPacketError {
  self.check_available!(size)
  self.pos += size
}

///|
pub fn skip_byte(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(1)
}

///|
pub fn skip_short(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(2)
}

///|
pub fn skip_int(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(4)
}

///|
pub fn skip_long(self : InPacket) -> Unit!ReadPacketError {
  self.skip!(8)
}

///|
fn read_le_uint16(bytes : Bytes, offset : Int) -> UInt {
  bytes[offset].to_uint() + (bytes[offset + 1].to_uint() << 8)
}

///|
fn read_le_uint32(bytes : Bytes, offset : Int) -> UInt {
  bytes[offset].to_uint() +
  (bytes[offset + 1].to_uint() << 8) +
  (bytes[offset + 2].to_uint() << 16) +
  (bytes[offset + 3].to_uint() << 24)
}

///|
fn read_le_uint64(bytes : Bytes, offset : Int) -> UInt64 {
  bytes[offset].to_uint().to_uint64() +
  (bytes[offset + 1].to_uint().to_uint64() << 8) +
  (bytes[offset + 2].to_uint().to_uint64() << 16) +
  (bytes[offset + 3].to_uint().to_uint64() << 24) +
  (bytes[offset + 4].to_uint().to_uint64() << 32) +
  (bytes[offset + 5].to_uint().to_uint64() << 40) +
  (bytes[offset + 6].to_uint().to_uint64() << 48) +
  (bytes[offset + 7].to_uint().to_uint64() << 56)
}

///|
pub fn read_point(self : InPacket) -> @struct.Point[Int]!ReadPacketError {
  { x: self.read_short!(), y: self.read_short!() }
}

///|
pub type! ReadPacketError String

///|
pub impl Show for ReadPacketError with output(self, logger) {
  match self {
    ReadPacketError(err) => logger.write_string(err)
  }
}
