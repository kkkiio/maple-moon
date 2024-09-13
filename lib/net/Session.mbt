struct Session {
  forwarder : (Bytes) -> Unit
  mut conn : Connection
}

enum Connection {
  CLOSED
  OPENED(Socket)
  READY(~socket : Socket)
}

pub fn Session::new(forwarder : (Bytes) -> Unit) -> Session {
  { forwarder, conn: CLOSED }
}

pub fn close(self : Session) -> Unit {
  match self.conn {
    OPENED(socket) => {
      socket.close()
      self.conn = CLOSED
    }
    READY(~socket, ..) => {
      socket.close()
      self.conn = CLOSED
    }
    CLOSED => ()
  }
}

pub fn connect(self : Session, path : String) -> Unit {
  // Connect to the server
  match self.conn {
    CLOSED => self.conn = OPENED(Socket::open(path.to_js_string()))
    _ => {
      @log.warn({ "path": path }, "previous connection still open")
      panic()
    }
  }
}

/// Send a packet to the server
pub fn write(self : Session, bytes : Bytes) -> Unit {
  match self.conn {
    READY(~socket, ..) => socket.write(bytes)
    _ =>
      @log.warn(
        { "blen": bytes.length() },
        "faild to write, connection not established",
      )
  }
}

/// Check for incoming packets and handle them
pub fn read(self : Session) -> Unit {
  match self.conn {
    CLOSED => ()
    OPENED(socket) => if socket.is_connected() { self.conn = READY(~socket) }
    READY(_) as conn => {
      let res = conn.socket.read()
      if res.bytes.length() > 0 {
        (self.forwarder)(res.bytes)
      }
      if res.eof {
        conn.socket.close()
        self.conn = CLOSED
        return
      }
    }
  }
}

pub enum ConnectionStatus {
  CLOSED
  OPENED
  READY
} derive(Show, Eq)

/// Check if the connection is alive
pub fn get_status(self : Session) -> ConnectionStatus {
  match self.conn {
    CLOSED => CLOSED
    OPENED(_) => OPENED
    READY(_) => READY
  }
}

type Socket

fn Socket::open(path : Js_string) -> Socket = "socket" "open"

fn close(self : Socket) -> Unit = "socket" "close"

fn is_connected(self : Socket) -> Bool = "socket" "is_connected"

struct ReadResult {
  bytes : Bytes
  eof : Bool
}

extern "js" fn read(self : Socket) -> ReadResult =
  #| (s) => s.read()

extern "js" fn write(self : Socket, packet : Bytes) -> Unit =
  #| (s,p) => s.write(p)
