struct Session {
  forwarder : Forwarder
  mut conn : Connection
  buffer : ChainedReadBytes
}

enum Connection {
  CLOSED
  OPEN(Socket)
  CONNECTED(~socket : Socket, ~cryptography : Cryptography, mut ~length : Int)
}

pub fn Session::new(forwarder : Forwarder) -> Session {
  { forwarder, conn: CLOSED, buffer: { dq: @deque.new(), fpos: 0, length: 0 } }
}

// fn Connection::new() -> Connection {
//   // Read keys necessary for communicating with the server
//   // self.cryptography = self.socket.get_buffer()
//   //   |> Cryptography::from_handshake
// }

pub fn close(self : Session) -> Unit {
  match self.conn {
    OPEN(socket) => {
      socket.close()
      self.conn = CLOSED
    }
    CONNECTED(~socket, ..) => {
      socket.close()
      self.conn = CLOSED
    }
    CLOSED => ()
  }
}

pub fn initialize(self : Session) -> Unit {
  self.connect()
}

pub fn connect(self : Session) -> Unit {
  // Connect to the server
  match self.conn {
    CLOSED => self.conn = OPEN(Socket::connect())
    _ => ()
  }
}

/// Send a packet to the server
pub fn write(self : Session, bytes : Bytes) -> Unit {

}

/// Check for incoming packets and handle them
pub fn read(self : Session) -> Unit {
  // Check if a packet has arrived. Handle if data is sufficient: 4 bytes
  // (header) + 2 bytes (opcode) = 6 bytes.
  match self.conn {
    CLOSED => ()
    OPEN(socket) => panic()
    CONNECTED(_) as conn => {
      let res = conn.socket.receive()
      if res.bytes.length() <= 0 {
        return
      }
      self.buffer.push(res.bytes)
      while true {
        // Retrieve buffer from the socket and process it
        if conn.length == 0 {
          if self.buffer.available() < header_length {
            return
          }
          // Position is zero, meaning this is the start of a new packet. Start by
          // determining length.
          conn.length = conn.cryptography.check_length(
            self.buffer.read_bytes(header_length),
          )
        }

        // Check if the current packet has been fully processed
        if self.buffer.available() < conn.length {
          return
        }
        let bs = self.buffer.read_bytes(conn.length)
        conn.cryptography.decrypt(bs)
        self.forwarder.forward(bs)
        conn.length = 0
      }
    }
  }
}

/// Closes the current connection and opens a new one with default connection
/// settings
pub fn reconnect_default(self : Session) -> Unit {

}

/// Closes the current connection and opens a new one
pub fn reconnect(self : Session, address : String, port : String) -> Unit {
  self.close()
  self.connect()
}

/// Check if the connection is alive
// pub fn is_connected(self : Session) -> Bool {
//   self.socket.is_connected()
// }

struct ChainedReadBytes {
  dq : @deque.Deque[Bytes]
  mut fpos : Int
  mut length : Int
}

fn push(self : ChainedReadBytes, bytes : Bytes) -> Unit {
  self.dq.push_back(bytes)
  self.length = self.length + bytes.length()
}

fn available(self : ChainedReadBytes) -> Int {
  self.length - self.fpos
}

fn read_bytes(self : ChainedReadBytes, length : Int) -> Bytes {
  let res = Bytes::new(length)
  let mut offset = 0
  while offset < length {
    let bs = self.dq.front().unwrap()
    let readn = @math.minimum(bs.length() - self.fpos, length - offset)
    res.blit(offset, bs, self.fpos, readn)
    if self.fpos + readn == bs.length() {
      self.dq.pop_front() |> ignore
      self.fpos = 0
      self.length = self.length - bs.length()
    }
    offset = offset + readn
  }
  res
}

type Socket

fn Socket::connect() -> Socket = "socket" "connect"

fn close(self : Socket) -> Unit = "socket" "close"

struct ReadResult {
  bytes : Bytes
  connected : Bool
}

extern "js" fn receive(self : Socket) -> ReadResult =
  #| (s) => ({bytes:null,connected:false})

// fn is_connected(self : Socket) -> Bool = "socket" "is_connected"
