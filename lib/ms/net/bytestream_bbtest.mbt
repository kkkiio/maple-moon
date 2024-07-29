test "test_read_bytes_5" {
  let byte_stream = ByteStream::new()
  byte_stream.add(Bytes::of([0x1, 0x2, 0x3]))
  byte_stream.add(Bytes::of([0x4, 0x5, 0x6]))
  @test.is_true!(byte_stream.read_bytes?(8).is_err())
}

test "test_read_bytes_4" {
  let byte_stream = ByteStream::new()
  byte_stream.add(Bytes::of([0x1, 0x2, 0x3]))
  byte_stream.add(Bytes::of([0x4, 0x5, 0x6]))
  @test.eq!(byte_stream.available(), 6)
  let bytes = byte_stream.read_bytes!(5)
  @test.eq!(bytes.length(), 5)
  @test.eq!(byte_stream.available(), 1)
  inspect!(bytes.to_array().join(""), content="12345")
}
