test "header" {
  let rand0 = 1
  let rand1 = 2
  let rand2 = 42
  let cryptography = Cryptography::new(
    Bytes::from_array([82, 48, 120, rand0].map(Int::to_byte)),
    Bytes::from_array([70, 114, 122, rand1].map(Int::to_byte)),
  )
  let buf = Bytes::new(header_length)
  cryptography.create_header(buf, rand2)
  @test.eq!(cryptography.check_length(buf), rand2)
}

test "ubyte" {
  let b = b'\xff'
  inspect!(b.to_int(), content="255")
  inspect!(b.to_uint(), content="255")
}

test "uint" {
  let i = 0xffffffffU
  inspect!(i.to_int(), content="-1")
}
