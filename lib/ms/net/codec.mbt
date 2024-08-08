// struct Session {
//   forwarder : Forwarder
//   mut conn : Connection
// }

// enum Connection {
//   CLOSED
//   OPENED(Socket)
//   READY(
//     ~socket : Socket,
//     ~cryptography : Cryptography,
//     ~input_stream : ByteStream,
//     mut ~next_packet_len : Int
//   )
// }

// pub fn Session::new(forwarder : Forwarder) -> Session {
//   { forwarder, conn: CLOSED }
// }

// pub fn close(self : Session) -> Unit {
//   match self.conn {
//     OPENED(socket) => {
//       socket.close()
//       self.conn = CLOSED
//     }
//     READY(~socket, ..) => {
//       socket.close()
//       self.conn = CLOSED
//     }
//     CLOSED => ()
//   }
// }

// pub fn connect(self : Session, path : String) -> Unit {
//   // Connect to the server
//   match self.conn {
//     CLOSED => self.conn = OPENED(Socket::open(path.to_js_string()))
//     _ => ()
//   }
// }

// /// Send a packet to the server
// pub fn write(self : Session, bytes : Bytes) -> Unit {
//   match self.conn {
//     READY(~socket, ~cryptography, ..) => {
//       let packet = Bytes::new(header_length + bytes.length())
//       cryptography.create_header(packet, bytes.length())
//       cryptography.encrypt(bytes)
//       packet.blit(header_length, bytes, 0, bytes.length())
//       socket.write(packet)
//     }
//     _ =>
//       @log.warn(
//         { "blen": bytes.length() },
//         "faild to write, connection not established",
//       )
//   }
// }

// /// Check for incoming packets and handle them
// pub fn read(self : Session) -> Unit {
//   // Check if a packet has arrived. Handle if data is sufficient: 4 bytes
//   // (header) + 2 bytes (opcode) = 6 bytes.
//   match self.conn {
//     CLOSED => ()
//     OPENED(socket) => {
//       let res = socket.read()
//       // let bsize = res.bytes.length()
//       // let eof = res.eof
//       // println("read handshake, bytes=\(bsize) bytes, eof=\(eof)")
//       if res.eof {
//         socket.close()
//         self.conn = CLOSED
//         return
//       }
//       if res.bytes.length() <= 0 {
//         return
//       }
//       if res.bytes.length() != handshake_len {
//         let actual = res.bytes.length()
//         println("expected handshake length, got \(actual)")
//         socket.close()
//         self.conn = CLOSED
//         return
//       }
//       let cryptography = Cryptography::from_handshake(res.bytes)
//       println("handshake success")
//       self.conn = READY(
//         ~socket,
//         ~cryptography,
//         input_stream=ByteStream::new(),
//         next_packet_len=0,
//       )
//     }
//     READY(_) as conn => {
//       let res = conn.socket.read()
//       if res.eof {
//         conn.socket.close()
//         self.conn = CLOSED
//         return
//       }
//       if res.bytes.length() <= 0 {
//         return
//       }
//       conn.input_stream.add(res.bytes)
//       while true {
//         // Retrieve buffer from the socket and process it
//         if conn.next_packet_len == 0 {
//           if conn.input_stream.available() < header_length {
//             return
//           }
//           // Position is zero, meaning this is the start of a new packet. Start by
//           // determining length.
//           conn.next_packet_len = conn.cryptography.check_length(
//             conn.input_stream.read_bytes?(header_length).unwrap(),
//           )
//         }

//         // Check if the current packet has been fully processed
//         if conn.input_stream.available() < conn.next_packet_len {
//           return
//         }
//         let bytes = conn.input_stream.read_bytes?(conn.next_packet_len).unwrap()
//         conn.cryptography.decrypt(bytes)
//         self.forwarder.forward(bytes)
//         conn.next_packet_len = 0
//       }
//     }
//   }
// }

// /// Closes the current connection and opens a new one
// pub fn reconnect(self : Session, path : String) -> Unit {
//   self.close()
//   self.connect(path)
// }

// pub enum ConnectionStatus {
//   CLOSED
//   OPENED
//   READY
// }

// /// Check if the connection is alive
// pub fn get_status(self : Session) -> ConnectionStatus {
//   match self.conn {
//     CLOSED => CLOSED
//     OPENED(_) => OPENED
//     READY(_) => READY
//   }
// }

// type Socket

// fn Socket::open(path : Js_string) -> Socket = "socket" "open"

// fn close(self : Socket) -> Unit = "socket" "close"

// struct ReadResult {
//   bytes : Bytes
//   eof : Bool
// }

// extern "js" fn read(self : Socket) -> ReadResult =
//   #| (s) => s.read()

// extern "js" fn write(self : Socket, packet : Bytes) -> Unit =
//   #| (s,p) => s.write(p)
