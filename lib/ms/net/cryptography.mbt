struct Cryptography {
  sendiv : FixedArray[Byte]
  recviv : FixedArray[Byte]
}

pub fn Cryptography::from_handshake(handshake : Bytes) -> Cryptography {
  let sendiv = FixedArray::new_with_index(
    header_length,
    fn(i) { handshake[i + 7] },
  )
  let recviv = FixedArray::new_with_index(
    header_length,
    fn(i) { handshake[i + 11] },
  )
  { sendiv, recviv }
}

pub fn check_length(self : Cryptography, bytes : Bytes) -> Int {
  panic()
}

pub fn decrypt(self : Cryptography, bytes : Bytes) -> Unit {

}
