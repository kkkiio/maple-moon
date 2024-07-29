struct ByteStream {
  dq : @deque.T[Bytes]
  mut fpos : Int
  mut length : Int
}

pub fn ByteStream::new() -> ByteStream {
  { dq: @deque.new(), fpos: 0, length: 0 }
}

pub fn add(self : ByteStream, bytes : Bytes) -> Unit {
  self.dq.push_back(bytes)
  self.length = self.length + bytes.length()
}

pub fn available(self : ByteStream) -> Int {
  self.length - self.fpos
}

pub fn read_bytes(self : ByteStream, length : Int) -> Bytes!String {
  let res = Bytes::new(length)
  let mut offset = 0
  while offset < length {
    let bs = self.dq.front().or_error!("not enough bytes available")
    let n = @math.minimum(bs.length() - self.fpos, length - offset)
    res.blit(offset, bs, self.fpos, n)
    self.fpos += n
    if self.fpos == bs.length() {
      self.dq.pop_front() |> ignore
      self.fpos = 0
      self.length -= bs.length()
    }
    offset += n
  }
  res
}
