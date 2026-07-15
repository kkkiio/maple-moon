///|
enum CdpReply {
  Result(Json)
  Failure(String)
}

///|
#borrow(buffer)
extern "C" fn fill_secure_random(
  buffer : FixedArray[Byte],
  length : Int,
) -> Unit = "maple_moon_fill_secure_random"

///|
struct NativeCdp {
  socket : @websocket.Conn
  mut open : Bool
  mut next_id : Int
  pending : Map[Int, (String, @async.Queue[CdpReply])]
}

///|
fn temp_path(name : String) -> String {
  let temp_dir = @env.get_env_var("TMPDIR").unwrap_or("/tmp")
  @path.Path(temp_dir).join(@path.Path(name)).to_string()
}

///|
fn now_ms() -> Double {
  @env.now().to_double()
}

///|
async fn write_state_file(path : String, content : String) -> Unit {
  let temporary = path + ".tmp"
  @fs.write_file(
    temporary,
    content,
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
  @fs.rename(temporary, path)
  @fs.chmod(path, 0o600)
}

///|
async fn remove_path(path : String) -> Unit {
  if @fs.exists(path) {
    @fs.remove(path)
  }
}

///|
async fn write_base64_file(path : String, content : String) -> Unit {
  let destination = @path.Path(path).resolve()
  let parent = destination.dirname().to_string()
  if parent != "" && !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  @fs.write_file(
    destination.to_string(),
    @base64.decode(content),
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
}

///|
async fn find_chrome() -> String {
  let candidates = [
    @env.get_env_var("CHROME_BIN").unwrap_or(""),
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
  ]
  for candidate in candidates {
    if candidate != "" && @fs.exists(candidate) {
      return candidate
    }
  }
  ""
}

///|
fn encode_uri_component(value : String) -> String {
  let bytes = @utf8.encode(value)
  let output = StringBuilder::new()
  let hex = "0123456789ABCDEF"
  for byte in bytes {
    let code = byte.to_int()
    if (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      (code >= 48 && code <= 57) ||
      code == 45 ||
      code == 46 ||
      code == 95 ||
      code == 126 {
      output.write_char(code.unsafe_to_char())
    } else {
      output.write_char('%')
      output.write_char(hex[(code >> 4) & 15].to_int().unsafe_to_char())
      output.write_char(hex[code & 15].to_int().unsafe_to_char())
    }
  }
  output.to_string()
}

///|
async fn NativeCdp::receive(
  self : NativeCdp,
  on_event : (String) -> Unit,
  on_close : () -> Unit,
) -> Unit {
  try {
    while self.open {
      let message = self.socket.recv()
      let text = message.read_all().text()
      let json = @json.parse(text) catch {
        _ => {
          on_event(text)
          continue
        }
      }
      match json {
        { "id": Number(id, ..), "error": error, .. } =>
          if self.pending.get(id.to_int()) is Some((command, reply)) {
            self.pending.remove(id.to_int())
            let detail = match error {
              { "message": String(message), .. } => message
              _ => error.stringify()
            }
            ignore(
              reply.try_put(Failure("\{command}: \{detail}")) catch {
                _ => false
              },
            )
          }
        { "id": Number(id, ..), "result": result, .. } =>
          if self.pending.get(id.to_int()) is Some((_, reply)) {
            self.pending.remove(id.to_int())
            ignore(reply.try_put(Result(result)) catch { _ => false })
          }
        { "id": Number(id, ..), .. } =>
          if self.pending.get(id.to_int()) is Some((_, reply)) {
            self.pending.remove(id.to_int())
            ignore(
              reply.try_put(Result(Json::empty_object())) catch {
                _ => false
              },
            )
          }
        _ => on_event(text)
      }
    }
  } catch {
    _ => ()
  }
  self.open = false
  for _, pending in self.pending {
    let (_, reply) = pending
    ignore(reply.try_put(Failure("CDP WebSocket closed")) catch { _ => false })
  }
  self.pending.clear()
  on_close()
}

///|
async fn NativeCdp::send(
  self : NativeCdp,
  command_method : String,
  params : Json,
) -> Json {
  guard self.open else { fail("CDP WebSocket is not connected") }
  let id = self.next_id
  self.next_id += 1
  let reply = @async.Queue(kind=Blocking(1))
  self.pending[id] = (command_method, reply)
  try {
    self.socket.send_text(
      ({ "id": id, "method": command_method, "params": params } : Json).stringify(),
    )
    match @async.with_timeout(30000, () => reply.get()) {
      Result(result) => result
      Failure(message) => fail(message)
    }
  } catch {
    error => {
      self.pending.remove(id)
      raise error
    }
  }
}

///|
fn NativeCdp::close(self : NativeCdp) -> Unit {
  guard self.open else { return }
  self.open = false
  self.socket.close()
}

///|
async fn open_cdp(
  url : String,
  group : @async.TaskGroup[String],
  on_event : (String) -> Unit,
  on_close : () -> Unit,
) -> NativeCdp {
  let cdp = NativeCdp::{
    socket: @websocket.Conn::connect(url),
    open: true,
    next_id: 1,
    pending: Map([]),
  }
  group.spawn_bg(allow_failure=true, () => cdp.receive(on_event, on_close))
  cdp
}
