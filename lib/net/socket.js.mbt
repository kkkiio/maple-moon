extern "js" fn read(self : Socket) -> Bytes =
  #| (s) => s.read()

extern "js" fn write(self : Socket, packet : Bytes) -> Unit =
  #| (s,p) => s.write(p)

extern "js" fn Socket::open(path : String) -> Socket =
  #| (p) => socket.open(p)
