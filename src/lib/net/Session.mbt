///|
struct Session {
  forwarder : (Bytes) -> Unit
  mut conn : Connection
}

///|
priv enum Connection {
  CLOSED
  OPENED(Socket)
  READY(socket~ : Socket)
}

///|
pub fn Session::new(forwarder : (Bytes) -> Unit) -> Session {
  { forwarder, conn: CLOSED }
}

///|
pub fn close(self : Session) -> Unit {
  match self.conn {
    OPENED(socket) => {
      socket.close()
      self.conn = CLOSED
    }
    READY(socket~) => {
      socket.close()
      self.conn = CLOSED
    }
    CLOSED => ()
  }
}

///|
pub fn connect(self : Session, path : String) -> Unit {
  // Connect to the server
  match self.conn {
    CLOSED => self.conn = OPENED(Socket::open(path))
    _ => {
      @log.warn({ "path": path }, "previous connection still open")
      panic()
    }
  }
}

///| Send a packet to the server
pub fn write(self : Session, bytes : Bytes) -> Unit {
  match self.conn {
    READY(socket~) => socket.write(bytes)
    _ =>
      @log.warn(
        { "blen": bytes.length() },
        "faild to write, connection not established",
      )
  }
}

///| Check for incoming packets and handle them
pub fn read(self : Session) -> Unit {
  match self.conn {
    CLOSED => ()
    OPENED(socket) =>
      match socket.get_ready_state() {
        // open
        1 => self.conn = READY(socket~)
        // closing or closed
        2 | 3 => self.conn = CLOSED
        _ => ()
      }
    READY(_) as conn => {
      let bytes = conn.socket.read()
      if bytes.length() > 0 {
        (self.forwarder)(bytes)
      }
    }
  }
}

///|
pub enum ConnectionStatus {
  CLOSED
  OPENED
  READY
} derive(Show, Eq)

///| Check if the connection is alive
pub fn Session::get_status(self : Session) -> ConnectionStatus {
  match self.conn {
    CLOSED => CLOSED
    OPENED(_) => OPENED
    READY(_) => READY
  }
}

///|
#external
priv type Socket

///|
fn Socket::close(self : Socket) -> Unit = "socket" "close"

///|
fn Socket::get_ready_state(self : Socket) -> Int = "socket" "get_ready_state"
