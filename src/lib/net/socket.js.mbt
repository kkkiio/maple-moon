///|
extern "js" fn Socket::read(self : Socket) -> Bytes =
  #| (s) => s.read()

///| Bytes is js Array
extern "js" fn Socket::write(self : Socket, packet : Bytes) -> Unit =
  #| (s,p) => s.write(Uint8Array.from(p))

///|
extern "js" fn Socket::open(path : String) -> Socket =
  #| (p) => socket.open(p)
