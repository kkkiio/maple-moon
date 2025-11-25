///|
struct Server {
  queue : @queue.T[&OutMessage]
}

///|
pub fn Server::new() -> Server {
  Server::{ queue: @queue.new() }
}

///|
/// send message to the server
#callsite(autofill(loc))
pub fn[T : OutMessage] Server::send_message(
  self : Server,
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  // TODO: implement
  @log.log(log_level, { "message": message.to_string() }, "send", loc~)
  // self.process_out(message.pack().encode())
}
