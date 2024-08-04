test "test_read_bytes_5" {
  let byte_stream = ByteStream::new()
  byte_stream.add(Bytes::of([b'\x01', b'\x02', b'\x03']))
  byte_stream.add(Bytes::of([b'\x04', b'\x05', b'\x06']))
  @test.is_true!(byte_stream.read_bytes?(8).is_err())
}

test "test_read_bytes_4" {
  let byte_stream = ByteStream::new()
  byte_stream.add(Bytes::of([b'\x01', b'\x02', b'\x03']))
  byte_stream.add(Bytes::of([b'\x04', b'\x05', b'\x06']))
  @test.eq!(byte_stream.available(), 6)
  let bytes = byte_stream.read_bytes!(5)
  @test.eq!(bytes.length(), 5)
  @test.eq!(byte_stream.available(), 1)
  inspect!(bytes.to_array().join(""), content="12345")
}
