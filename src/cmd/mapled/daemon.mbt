///|
struct LogEntry {
  time : Double
  level : String
  source : String
  text : String
  url : String?
  line : Int?
}

///|
fn LogEntry::to_json(self : LogEntry) -> Json {
  let fields : Map[String, Json] = {
    "time": self.time,
    "level": self.level,
    "source": self.source,
    "text": self.text,
  }
  match self.url {
    Some(url) => fields["url"] = Json::string(url)
    None => ()
  }
  match self.line {
    Some(line) => fields["line"] = Json::number(line.to_double())
    None => ()
  }
  Json::object(fields)
}

///|
struct NetworkEntry {
  request_id : String
  start : Double
  mut url : String?
  mut request_method : String?
  mut type_ : String?
  mut started_at : Double?
  mut status : Int?
  mut mime : String?
  mut finished_at : Double?
  mut size : Double?
  mut duration_ms : Double?
  mut failed : Bool?
  mut error : String?
  mut canceled : Bool?
}

///|
fn NetworkEntry::to_json(self : NetworkEntry) -> Json {
  let fields : Map[String, Json] = {
    "requestId": self.request_id,
    "start": self.start,
  }
  if self.url is Some(value) { fields["url"] = Json::string(value) }
  if self.request_method is Some(value) {
    fields["method"] = Json::string(value)
  }
  if self.type_ is Some(value) { fields["type"] = Json::string(value) }
  if self.started_at is Some(value) { fields["started_at"] = Json::number(value) }
  if self.status is Some(value) {
    fields["status"] = Json::number(value.to_double())
  }
  if self.mime is Some(value) { fields["mime"] = Json::string(value) }
  if self.finished_at is Some(value) { fields["finished_at"] = Json::number(value) }
  if self.size is Some(value) { fields["size"] = Json::number(value) }
  if self.duration_ms is Some(value) { fields["duration_ms"] = Json::number(value) }
  if self.failed is Some(value) {
    fields["failed"] = Json::boolean(value)
  }
  if self.error is Some(value) { fields["error"] = Json::string(value) }
  if self.canceled is Some(value) {
    fields["canceled"] = Json::boolean(value)
  }
  Json::object(fields)
}

///|
enum NetworkUpdate {
  RequestSent(
    url~ : String,
    request_method~ : String,
    type_~ : String,
    time~ : Double,
  )
  ResponseReceived(url~ : String, status~ : Int, mime~ : String, type_~ : String)
  LoadingFinished(time~ : Double, size~ : Double)
  LoadingFailed(time~ : Double, error~ : String, canceled~ : Bool)
}

///|
struct Daemon {
  cdp_port : Int
  mut game_url : String
  socket_path : String
  state_path : String
  pid_path : String
  user_data_dir : String
  logs : Array[LogEntry]
  requests : Map[String, NetworkEntry]
  request_order : Array[String]
  mut cdp : JsCdp?
  mut chrome : JsChrome?
  mut server : JsServer?
  mut finished : Bool
  stop : JsStopSignal
}

///|
fn Daemon::new(cdp_port : Int, game_url : String) -> Daemon {
  {
    cdp_port,
    game_url,
    socket_path: temp_path("maple-moon-mapled.sock"),
    state_path: temp_path("maple-moon-mapled.state.json"),
    pid_path: temp_path("maple-moon-mapled.pid"),
    user_data_dir: temp_path("maple-moon-chrome-profile"),
    logs: [],
    requests: {},
    request_order: [],
    cdp: None,
    chrome: None,
    server: None,
    finished: false,
    stop: new_stop_signal(),
  }
}

///|
fn Daemon::write_state(self : Daemon, phase : String) -> Unit {
  let state : Json = {
    "phase": phase,
    "pid": process_pid(),
    "updated_at": now_ms() / 1000.0,
    "config": {
      "cdpPort": self.cdp_port,
      "gameUrl": self.game_url,
    },
  }
  write_state_file(self.state_path, state.stringify())
}

///|
fn Daemon::push_log(
  self : Daemon,
  level : String,
  source : String,
  text : String,
  url? : String,
  line? : Int,
) -> Unit {
  let entry : LogEntry = { time: now_ms(), level, source, text, url, line }
  self.logs.push(entry)
  if self.logs.length() > 1000 {
    ignore(self.logs.drain(0, self.logs.length() - 1000))
  }
  match self.server {
    Some(server) => {
      let event : Json = { "event": "log", "entry": entry.to_json() }
      server_broadcast(server, event.stringify() + "\n")
    }
    None => ()
  }
}

///|
fn Daemon::remember_network(
  self : Daemon,
  request_id : String,
  update : NetworkUpdate,
) -> NetworkEntry {
  let entry = match self.requests.get(request_id) {
    Some(entry) => entry
    None => {
      let entry : NetworkEntry = {
        request_id,
        start: now_ms(),
        url: None,
        request_method: None,
        type_: None,
        started_at: None,
        status: None,
        mime: None,
        finished_at: None,
        size: None,
        duration_ms: None,
        failed: None,
        error: None,
        canceled: None,
      }
      self.requests[request_id] = entry
      self.request_order.push(request_id)
      entry
    }
  }
  match update {
    RequestSent(url~, request_method~, type_~, time~) => {
      entry.url = Some(url)
      entry.request_method = Some(request_method)
      entry.type_ = Some(type_)
      entry.started_at = Some(time)
    }
    ResponseReceived(url~, status~, mime~, type_~) => {
      entry.url = Some(url)
      entry.status = Some(status)
      entry.mime = Some(mime)
      entry.type_ = Some(type_)
    }
    LoadingFinished(time~, size~) => {
      entry.finished_at = Some(time)
      entry.size = Some(size)
      if entry.started_at is Some(started_at) {
        entry.duration_ms = Some(time - started_at)
      }
    }
    LoadingFailed(time~, error~, canceled~) => {
      entry.failed = Some(true)
      entry.error = Some(error)
      entry.canceled = Some(canceled)
      entry.finished_at = Some(time)
    }
  }
  if self.request_order.length() > 500 {
    let expired = self.request_order.drain(0, self.request_order.length() - 500)
    for id in expired { ignore(self.requests.remove(id)) }
  }
  entry
}

///|
fn Daemon::handle_cdp_event(self : Daemon, message : String) -> Unit {
  let event = @mapled_protocol.summarize_cdp_event(message, now_ms())
  match event {
    {
      "kind": "log",
      "level": String(level),
      "source": String(source),
      "text": String(text),
      ..
    } => {
      let url = match event {
        { "url": String(value), .. } => Some(value)
        _ => None
      }
      let line = match event {
        { "line": Number(value, ..), .. } => Some(value.to_int())
        _ => None
      }
      self.push_log(level, source, text, url?, line?)
    }
    { "kind": "invalid", "error": String(error), .. } =>
      self.push_log("error", "cdp", "invalid CDP message: \{error}")
    {
      "kind": "network-request",
      "requestId": String(request_id),
      "url": String(url),
      "method": String(request_method),
      "type": String(type_),
      "time": Number(time, ..),
      ..
    } =>
      ignore(
        self.remember_network(
          request_id,
          RequestSent(url~, request_method~, type_~, time~),
        ),
      )
    {
      "kind": "network-response",
      "requestId": String(request_id),
      "url": String(url),
      "status": Number(status, ..),
      "mime": String(mime),
      "type": String(type_),
      ..
    } => {
      ignore(
        self.remember_network(
          request_id,
          ResponseReceived(url~, status=status.to_int(), mime~, type_~),
        ),
      )
      if status >= 400.0 {
        self.push_log("error", "network", "HTTP \{status.to_int()}: \{url}")
      }
    }
    {
      "kind": "network-finished",
      "requestId": String(request_id),
      "size": Number(size, ..),
      "time": Number(time, ..),
      ..
    } => ignore(self.remember_network(request_id, LoadingFinished(time~, size~)))
    {
      "kind": "network-failed",
      "requestId": String(request_id),
      "error": String(error),
      "canceled": canceled,
      "time": Number(time, ..),
      ..
    } => {
      let canceled = canceled is True
      let entry = self.remember_network(
        request_id,
        LoadingFailed(time~, error~, canceled~),
      )
      let url = entry.url.unwrap_or("")
      self.push_log("error", "network", "request failed: \{error} \{url}")
    }
    _ => ()
  }
}

///|
async fn Daemon::send_cdp(
  self : Daemon,
  command_method : String,
  params : Json,
) -> Json {
  let cdp = match self.cdp {
    Some(cdp) if cdp_is_open(cdp) => cdp
    _ => fail("CDP WebSocket is not connected")
  }
  let response = cdp_send(cdp, command_method, params.stringify()).wait()
  @json.parse(response)
}

///|
async fn Daemon::evaluate(
  self : Daemon,
  expression : String,
  await_promise : Bool,
) -> Json {
  let response = self.send_cdp("Runtime.evaluate", {
    "expression": expression,
    "awaitPromise": await_promise,
    "returnByValue": true,
    "userGesture": true,
  })
  match response {
    {
      "exceptionDetails": {
        "exception": { "description": String(description), .. },
        ..
      },
      ..
    } => fail(description)
    { "exceptionDetails": { "text": String(text), .. }, .. } => fail(text)
    { "exceptionDetails": _, .. } => fail("Runtime.evaluate failed")
    { "result": { "value": value, .. }, .. } => value
    { "result": { "description": String(description), .. }, .. } =>
      Json::string(description)
    _ => Json::null()
  }
}

///|
async fn Daemon::ensure_game_active(self : Daemon) -> Json {
  let mut state = Json::null()
  let mut select_result = Json::null()
  let mut create_result = Json::null()
  for _ in 0..<90 {
    let state_value = self.evaluate(
      "globalThis.$console.render_game_to_text()",
      true,
    )
    state = match state_value {
      String(text) => @json.parse(text)
      value => value
    }
    if state is { "phase": "GameActive", .. } {
      return {
        "createdCharacter": create_result != Json::null(),
        "createResult": create_result,
        "selectedCharacter": select_result != Json::null(),
        "selectResult": select_result,
        "state": state,
      }
    }
    if state is { "phase": "SelectCharacter", .. } &&
      select_result == Json::null() {
      let result = self.evaluate(
        "globalThis.$console.cmd(\"select_char\", \"0\")",
        true,
      )
      if result is { "ok": True, .. } ||
        result is { "code": "SELECT_CHAR_ALREADY_REQUESTED", .. } {
        select_result = result
      } else if result is { "code": "INVALID_SLOT", .. } &&
        create_result == Json::null() {
        let created = self.evaluate(
          "globalThis.$console.cmd(\"new_character\")",
          true,
        )
        if created is { "ok": True, .. } { create_result = created }
      }
    }
    ignore(self.evaluate("globalThis.$console.step(10)", true))
  }
  let phase = match state {
    { "phase": String(value), .. } => value
    _ => "unknown"
  }
  fail("game did not enter GameActive; current phase=\{phase}")
}

///|
async fn Daemon::run_bot(self : Daemon, request : Json) -> Json {
  let mut console_ready = false
  let console_deadline = now_ms() + 30000.0
  while now_ms() < console_deadline {
    try self.evaluate("typeof globalThis.$console", false) catch {
      _ => ()
    } noraise {
      String("object") => console_ready = true
      _ => ()
    }
    if console_ready { break }
    @async.sleep(250)
  }
  guard console_ready else {
    fail("globalThis.$console was not installed before timeout")
  }
  let entry = self.ensure_game_active()
  let timeout_ms = match request {
    { "timeoutMs": Number(value, ..), .. } if value.to_int() > 0 => value.to_int()
    _ => 120000
  }
  let script_path = match request {
    { "scriptPath": String(value), .. } => value
    _ => "playtest-script.js"
  }
  let script = match request {
    { "script": String(value), .. } => value
    _ => ""
  }
  let mut bot_ready = false
  let bot_deadline = now_ms() + 30000.0
  while now_ms() < bot_deadline {
    try self.evaluate("typeof globalThis.__bot", false) catch {
      _ => ()
    } noraise {
      String("object") => bot_ready = true
      _ => ()
    }
    if bot_ready { break }
    ignore(self.evaluate("globalThis.$console.step(5)", true))
  }
  guard bot_ready else { fail("globalThis.__bot was not installed before timeout") }
  let before_logs = self.logs.length()
  let before_requests = self.request_order.length()
  let source_url = script_path.replace_all(old="\\", new="/")
  let wrapped = "(async () => {\n\{script}\n})()\n//# sourceURL=\{source_url}"
  let promise = @js_async.Promise::from_async(() => {
    self.evaluate(wrapped, true).stringify()
  })
  let observed = observe_promise(promise)
  let deadline = now_ms() + timeout_ms.to_double()
  while !observed_settled(observed) && now_ms() < deadline {
    ignore(self.evaluate("globalThis.$console.step(1)", true))
  }
  let mut run_error : String? = None
  let mut result = Json::null()
  if !observed_settled(observed) {
    let message = "bot script timed out after \{timeout_ms}ms"
    run_error = Some(message)
    let cancel_expression = "globalThis.__bot_cancel_pending?.(\{Json::string(message).stringify()})"
    try self.evaluate(cancel_expression, false) catch {
      _ => ()
    } noraise {
      _ => ()
    }
    let settle_deadline = now_ms() + 1000.0
    while !observed_settled(observed) && now_ms() < settle_deadline {
      @async.sleep(20)
    }
  } else if observed_ok(observed) {
    result = @json.parse(observed_value(observed))
  } else {
    run_error = Some(observed_error(observed))
  }
  let state = try self.evaluate(
      "globalThis.$console.render_game_to_text()",
      true,
    ) catch {
      error => ({ "error": error.to_string() } : Json)
    } noraise {
      String(text) =>
        @json.parse(text) catch { err => ({ "error": err.to_string() } : Json) }
      value => value
    }
  let entries : Array[NetworkEntry] = []
  for id in self.request_order.view(start=before_requests) {
    if self.requests.get(id) is Some(value) { entries.push(value) }
  }
  let failures = entries.filter(entry =>
    entry.failed == Some(true) || entry.status.unwrap_or(0) >= 400
  )
  let recent_errors = self.logs.view(start=before_logs).filter(entry =>
    entry.level == "error"
  )
  let playtest_logs = self.logs.view(start=before_logs).filter(entry =>
    entry.text.contains("[playtest]")
  )
  let failures = failures.view(start=if failures.length() > 80 { failures.length() - 80 } else { 0 }).map(entry => entry.to_json())
  let recent_errors = recent_errors.view(start=if recent_errors.length() > 80 { recent_errors.length() - 80 } else { 0 }).map(entry => entry.to_json())
  let playtest_logs = playtest_logs.view(start=if playtest_logs.length() > 120 { playtest_logs.length() - 120 } else { 0 }).map(entry => entry.to_json())
  {
    "ok": true,
    "passed": run_error is None && failures.is_empty() && recent_errors.is_empty(),
    "scriptPath": script_path,
    "timeoutMs": timeout_ms,
    "entry": entry,
    "result": result,
    "error": match run_error { Some(value) => Json::string(value); None => Json::null() },
    "failures": failures,
    "recentErrors": recent_errors,
    "playtestLogs": playtest_logs,
    "state": state,
  }
}

///|
async fn Daemon::connect_chrome(self : Daemon, wait_for_url : Bool) -> Unit {
  let chrome_path = find_chrome()
  guard chrome_path != "" else { fail("Chrome executable not found; set CHROME_BIN") }
  let attempts = if wait_for_url { 120 } else { 1 }
  let mut url_ready = false
  for attempt in 0..<attempts {
    try fetch_http(self.game_url, "HEAD").wait() catch {
      _ => ()
    } noraise {
      text =>
        if @json.parse(text) is { "status": Number(status, ..), .. } &&
          status < 400.0 {
          url_ready = true
        }
    }
    if url_ready { break }
    if attempt + 1 < attempts { @async.sleep(250) }
  }
  guard url_ready else { fail("URL did not become ready: \{self.game_url}") }
  let list_url = "http://127.0.0.1:\{self.cdp_port}/json/list"
  let mut target : String? = None
  try fetch_http(list_url, "GET").wait() catch {
    _ => ()
  } noraise {
    text =>
      if @json.parse(text) is { "body": String(body), .. } {
        target = @mapled_protocol.select_cdp_target(
          @json.parse(body),
          self.game_url,
        )
      }
  }
  if target is None {
    let new_url = "http://127.0.0.1:\{self.cdp_port}/json/new?\{encode_uri_component(self.game_url)}"
    try fetch_http(new_url, "PUT").wait() catch {
      _ => ()
    } noraise {
      text =>
        if @json.parse(text) is { "body": String(body), .. } &&
          @json.parse(body) is { "webSocketDebuggerUrl": String(url), .. } {
          target = Some(url)
        }
    }
  }
  if target is None {
    let spawned = spawn_chrome(
      chrome_path,
      self.cdp_port,
      self.user_data_dir,
      self.game_url,
      (child, code, signal) => {
        if self.chrome is Some(current) && same_chrome(current, child) {
          self.chrome = None
        }
        if !self.finished {
          self.push_log(
            "warning",
            "mapled",
            "Chrome exited code=\{code} signal=\{signal}; run maple open to reconnect",
          )
        }
      },
    )
    self.chrome = Some(spawned)
  }
  for _ in 0..<80 {
    try fetch_http(list_url, "GET").wait() catch {
      _ => ()
    } noraise {
      text =>
        if @json.parse(text) is { "body": String(body), .. } {
          target = @mapled_protocol.select_cdp_target(
            @json.parse(body),
            self.game_url,
          )
        }
    }
    if target is Some(_) { break }
    @async.sleep(250)
  }
  let target = match target {
    Some(target) => target
    None => fail("No CDP page target found on port \{self.cdp_port}")
  }
  let socket = open_cdp(
    target,
    message => self.handle_cdp_event(message),
    closed => {
      if self.cdp is Some(current) && same_cdp(current, closed) {
        self.cdp = None
      }
      if !self.finished {
        self.push_log(
          "warning",
          "cdp",
          "browser disconnected; run maple open to reconnect",
        )
      }
    },
  ).wait()
  self.cdp = Some(socket)
  ignore(self.send_cdp("Runtime.enable", {}))
  ignore(self.send_cdp("Log.enable", {}))
  ignore(self.send_cdp("Network.enable", {}))
  ignore(self.send_cdp("Page.enable", {}))
}

///|
async fn Daemon::handle(self : Daemon, socket : JsSocket, request : Json) -> Json? {
  guard request is { "action": String(action), .. } else {
    fail("request action is required")
  }
  if action == "logs-follow" {
    for entry in self.logs {
      let event : Json = { "event": "log", "entry": entry.to_json() }
      socket_write(socket, event.stringify() + "\n")
    }
    match self.server {
      Some(server) => server_subscribe(server, socket)
      None => fail("mapled server is not listening")
    }
    return None
  }
  if action == "status" {
    let console_ready = try self.evaluate(
        "typeof globalThis.$console",
        false,
      ) catch {
        _ => false
      } noraise {
        String("object") => true
        _ => false
      }
    let connected = self.cdp is Some(cdp) && cdp_is_open(cdp)
    return Some({
      "ok": true,
      "pid": process_pid(),
      "url": self.game_url,
      "cdpPort": self.cdp_port,
      "browserConnected": connected,
      "consoleReady": console_ready,
      "logCount": self.logs.length(),
      "networkCount": self.request_order.length(),
    })
  }
  if action == "open" || action == "open-wait" {
    if self.cdp is Some(cdp) && cdp_is_open(cdp) {
      return Some({ "ok": true, "message": "browser already connected" })
    }
    if request is { "gameUrl": String(game_url), .. } && game_url != "" {
      self.game_url = game_url
    }
    self.connect_chrome(action == "open-wait")
    return Some({ "ok": true, "message": "browser opened" })
  }
  if action == "logs-clear" {
    self.logs.clear()
    return Some({ "ok": true, "message": "browser logs cleared" })
  }
  if action == "cmd" {
    let mut console_ready = false
    let deadline = now_ms() + 30000.0
    while now_ms() < deadline {
      try self.evaluate("typeof globalThis.$console", false) catch {
        _ => ()
      } noraise {
        String("object") => console_ready = true
        _ => ()
      }
      if console_ready { break }
      @async.sleep(250)
    }
    guard console_ready else {
      fail("globalThis.$console was not installed before timeout")
    }
    let command = match request {
      { "command": String(value), .. } => value
      _ => ""
    }
    let args = match request {
      { "args": Array(values), .. } => Json::array(values)
      _ => Json::array([])
    }
    let expression = "globalThis.$console.cmd(\{Json::string(command).stringify()}, ...\{args.stringify()})"
    return Some({ "ok": true, "result": self.evaluate(expression, true) })
  }
  if action == "eval" {
    let expression = match request {
      { "expression": String(value), .. } => value
      _ => ""
    }
    return Some({ "ok": true, "result": self.evaluate(expression, true) })
  }
  if action == "logs" {
    let wanted = match request {
      { "level": String(value), .. } => value
      _ => ""
    }
    let logs = self.logs.filter(entry => wanted == "" || entry.level == wanted)
    let start = if logs.length() > 200 { logs.length() - 200 } else { 0 }
    return Some({
      "ok": true,
      "logs": logs.view(start~).map(entry => entry.to_json()),
    })
  }
  if action == "network" {
    let failed_only = request is { "failed": True, .. }
    let entries : Array[NetworkEntry] = []
    for id in self.request_order {
      if self.requests.get(id) is Some(entry) &&
        (!failed_only ||
        entry.failed == Some(true) ||
        entry.status.unwrap_or(0) >= 400) {
        entries.push(entry)
      }
    }
    let start = if entries.length() > 200 { entries.length() - 200 } else { 0 }
    return Some({
      "ok": true,
      "entries": entries.view(start~).map(entry => entry.to_json()),
    })
  }
  if action == "screenshot" {
    let response = self.send_cdp("Page.captureScreenshot", {
      "format": "png",
      "captureBeyondViewport": false,
    })
    guard response is { "data": String(data), .. } else {
      fail("Page.captureScreenshot returned no data")
    }
    let out = match request {
      { "out": String(value), .. } if value != "" => value
      _ => "screenshot.png"
    }
    write_base64_file(out, data)
    return Some({ "ok": true, "out": out })
  }
  if action == "reload" {
    ignore(self.send_cdp("Page.reload", { "ignoreCache": true }))
    return Some({ "ok": true, "message": "reload requested" })
  }
  if action == "bot-run" { return Some(self.run_bot(request)) }
  if action == "wait-ready" {
    let mut console_ready = false
    let console_deadline = now_ms() + 30000.0
    while now_ms() < console_deadline {
      try self.evaluate("typeof globalThis.$console", false) catch {
        _ => ()
      } noraise {
        String("object") => console_ready = true
        _ => ()
      }
      if console_ready { break }
      @async.sleep(250)
    }
    guard console_ready else {
      fail("globalThis.$console was not installed before timeout")
    }
    let mut state = Json::null()
    for _ in 0..<90 {
      let value = self.evaluate(
        "globalThis.$console.render_game_to_text()",
        true,
      )
      state = match value { String(text) => @json.parse(text); value => value }
      if state is { "phase": "GameActive", .. } { break }
      ignore(self.evaluate("globalThis.$console.step(10)", true))
    }
    if state is { "phase": "GameActive", .. } {
      let response : Map[String, Json] = {
        "ok": true,
        "phase": "GameActive",
      }
      if state is { "map_id": map_id, .. } { response["map_id"] = map_id }
      return Some(Json::object(response))
    }
    let phase = match state {
      { "phase": String(value), .. } => value
      _ => "unknown"
    }
    return Some({
      "ok": false,
      "error": "game not active after waiting; current phase=\{phase}",
    })
  }
  if action == "close" {
    schedule(50, () => self.shutdown("close requested"))
    return Some({
      "ok": true,
      "pid": process_pid(),
      "message": "close requested",
    })
  }
  Some({ "ok": false, "error": "unknown action: \{action}" })
}

///|
async fn Daemon::handle_line(
  self : Daemon,
  socket : JsSocket,
  line : String,
) -> String {
  let request = @json.parse(line) catch {
    err => {
      self.push_log("error", "mapled", err.to_string())
      let response : Json = { "ok": false, "error": err.to_string() }
      return response.stringify()
    }
  }
  try self.handle(socket, request) catch {
    error => {
      self.push_log("error", "mapled", error.to_string())
      let response : Json = { "ok": false, "error": error.to_string() }
      response.stringify()
    }
  } noraise {
    Some(response) => response.stringify()
    None => ""
  }
}

///|
fn Daemon::shutdown(self : Daemon, reason : String) -> Unit {
  guard !self.finished else { return }
  self.finished = true
  let expected = reason == "close requested" ||
    reason == "SIGINT" ||
    reason == "SIGTERM"
  self.write_state(if expected { "stopped" } else { "failed" })
  if self.server is Some(server) {
    close_server(server)
    self.server = None
  }
  remove_path(self.socket_path)
  if self.cdp is Some(cdp) {
    close_cdp(cdp)
    self.cdp = None
  }
  if self.chrome is Some(chrome) {
    kill_chrome(chrome)
    self.chrome = None
  }
  remove_own_pid(self.pid_path, process_pid())
  resolve_stop(
    self.stop,
    if expected { "mapled stopped" } else { "mapled stopped: \{reason}" },
  )
}

///|
async fn Daemon::run(self : Daemon) -> String {
  try {
    self.write_state("initializing")
    self.write_state("starting")
    remove_path(self.socket_path)
    let server = start_server(
      self.socket_path,
      (socket, line) => @js_async.Promise::from_async(() => {
        self.handle_line(socket, line)
      }),
      message => self.push_log("error", "mapled", message),
    ).wait()
    self.server = Some(server)
    chmod_owner_only(self.socket_path)
    write_text_file(self.pid_path, process_pid().to_string())
    self.write_state("ready")
    install_signals(signal => self.shutdown(signal))
    self.push_log("info", "mapled", "listening on \{self.socket_path}")
    wait_stop(self.stop).wait()
  } catch {
    error => {
      self.write_state("failed")
      if self.server is Some(server) { close_server(server) }
      remove_path(self.socket_path)
      remove_own_pid(self.pid_path, process_pid())
      raise error
    }
  }
}
