///|
struct LogEntry {
  time : Double
  level : String
  source : String
  text : String
  url : String?
  line : Int?
} derive(ToJson)

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
} derive (
  ToJson(
    fields(
      request_id(rename="requestId"),
      request_method(rename="method"),
      type_(rename="type"),
    ),
  ),
)

///|
enum NetworkUpdate {
  RequestSent(
    url~ : String,
    request_method~ : String,
    type_~ : String,
    time~ : Double
  )
  ResponseReceived(
    url~ : String,
    status~ : Int,
    mime~ : String,
    type_~ : String
  )
  LoadingFinished(time~ : Double, size~ : Double)
  LoadingFailed(time~ : Double, error~ : String, canceled~ : Bool)
}

///|
struct LogSubscriber {
  id : Int
  queue : @async.Queue[String]
}

///|
struct Daemon {
  cdp_port : Int
  mut game_url : String
  state_path : String
  user_data_dir : String
  logs : Array[LogEntry]
  requests : Map[String, NetworkEntry]
  request_order : Array[String]
  subscribers : Array[LogSubscriber]
  mut next_subscriber_id : Int
  mut token : String
  mut cdp : NativeCdp?
  mut chrome : @process.Process?
  mut chrome_connecting : Bool
  mut chrome_connection_error : String?
  mut server : @socket.TcpServer?
  mut group : @async.TaskGroup[String]?
  mut finished : Bool
  stop : @async.Queue[String]
}

///|
fn Daemon::Daemon(cdp_port : Int, game_url : String) -> Daemon {
  {
    cdp_port,
    game_url,
    state_path: temp_path("maple-moon-mapled.state.json"),
    user_data_dir: temp_path("maple-moon-chrome-profile"),
    logs: [],
    requests: Map([]),
    request_order: [],
    subscribers: [],
    next_subscriber_id: 1,
    token: "",
    cdp: None,
    chrome: None,
    chrome_connecting: false,
    chrome_connection_error: None,
    server: None,
    group: None,
    finished: false,
    stop: @async.Queue(kind=Blocking(1)),
  }
}

///|
async fn Daemon::write_state(self : Daemon, phase : String) -> Unit {
  let state : Json = {
    "phase": phase,
    "updated_at": now_ms() / 1000.0,
    "endpoint": { "host": "127.0.0.1", "port": 39933 },
    "token": self.token,
    "config": { "cdpPort": self.cdp_port, "gameUrl": self.game_url },
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
  let event : Json = { "event": "log", "entry": ToJson::to_json(entry) }
  let line = event.stringify() + "\n"
  for subscriber in self.subscribers {
    ignore(subscriber.queue.try_put(line) catch { _ => false })
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
    for id in expired {
      ignore(self.requests.remove(id))
    }
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
    } =>
      ignore(self.remember_network(request_id, LoadingFinished(time~, size~)))
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
    Some(cdp) if cdp.open => cdp
    _ => fail("CDP WebSocket is not connected")
  }
  cdp.send(command_method, params)
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
      "globalThis.$console.render_game_to_text()", true,
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
        "globalThis.$console.cmd(\"select_char\", \"0\")", true,
      )
      if result is { "ok": True, .. } ||
        result is { "code": "SELECT_CHAR_ALREADY_REQUESTED", .. } {
        select_result = result
      } else if result is { "code": "INVALID_SLOT", .. } &&
        create_result == Json::null() {
        let created = self.evaluate(
          "globalThis.$console.cmd(\"new_character\")", true,
        )
        if created is { "ok": True, .. } {
          create_result = created
        }
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
    if console_ready {
      break
    }
    @async.sleep(250)
  }
  guard console_ready else {
    fail("globalThis.$console was not installed before timeout")
  }
  let entry = self.ensure_game_active()
  let timeout_ms = match request {
    { "timeoutMs": Number(value, ..), .. } if value.to_int() > 0 =>
      value.to_int()
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
    if bot_ready {
      break
    }
    ignore(self.evaluate("globalThis.$console.step(5)", true))
  }
  guard bot_ready else {
    fail("globalThis.__bot was not installed before timeout")
  }
  let before_logs = self.logs.length()
  let before_requests = self.request_order.length()
  let source_url = script_path.replace_all(old="\\", new="/")
  let wrapped = "(async () => {\n\{script}\n})()\n//# sourceURL=\{source_url}"
  let group = match self.group {
    Some(group) => group
    None => fail("mapled task group is unavailable")
  }
  let observed = group.spawn(allow_failure=true, () => {
    self.evaluate(wrapped, true)
  })
  let deadline = now_ms() + timeout_ms.to_double()
  let mut observed_result : Json? = None
  let mut observed_error : String? = None
  while observed_result is None && observed_error is None && now_ms() < deadline {
    try observed.try_wait() catch {
      error => observed_error = Some(error.to_string())
    } noraise {
      Some(value) => observed_result = Some(value)
      None => ignore(self.evaluate("globalThis.$console.step(1)", true))
    }
  }
  let mut run_error : String? = None
  let mut result = Json::null()
  if observed_result is None && observed_error is None {
    let message = "bot script timed out after \{timeout_ms}ms"
    run_error = Some(message)
    observed.cancel()
    let cancel_expression = "globalThis.__bot_cancel_pending?.(\{Json::string(message).stringify()})"
    try self.evaluate(cancel_expression, false) catch {
      _ => ()
    } noraise {
      _ => ()
    }
  } else if observed_result is Some(value) {
    result = value
  } else if observed_error is Some(error) {
    run_error = Some(error)
  }
  let state = try
    self.evaluate("globalThis.$console.render_game_to_text()", true)
  catch {
    error => ({ "error": error.to_string() } : Json)
  } noraise {
    String(text) =>
      @json.parse(text) catch {
        err => ({ "error": err.to_string() } : Json)
      }
    value => value
  }
  let entries = [
    for id in self.request_order.view(start=before_requests) if self.requests.get(
      id,
    )
    is Some(value) => value
  ]
  let failures = entries.filter(entry => {
    entry.failed == Some(true) || entry.status.unwrap_or(0) >= 400
  })
  let recent_errors = self.logs
    .view(start=before_logs)
    .filter(entry => entry.level == "error")
  let playtest_logs = self.logs
    .view(start=before_logs)
    .filter(entry => entry.text.contains("[playtest]"))
  let failures = failures
    .view(start=if failures.length() > 80 { failures.length() - 80 } else { 0 })
    .map(entry => ToJson::to_json(entry))
  let recent_errors = recent_errors
    .view(
      start=if recent_errors.length() > 80 {
        recent_errors.length() - 80
      } else {
        0
      },
    )
    .map(entry => ToJson::to_json(entry))
  let playtest_logs = playtest_logs
    .view(
      start=if playtest_logs.length() > 120 {
        playtest_logs.length() - 120
      } else {
        0
      },
    )
    .map(entry => ToJson::to_json(entry))
  {
    "ok": true,
    "passed": run_error is None &&
    failures.is_empty() &&
    recent_errors.is_empty(),
    "scriptPath": script_path,
    "timeoutMs": timeout_ms,
    "entry": entry,
    "result": result,
    "error": match run_error {
      Some(value) => Json::string(value)
      None => Json::null()
    },
    "failures": failures,
    "recentErrors": recent_errors,
    "playtestLogs": playtest_logs,
    "state": state,
  }
}

///|
async fn Daemon::connect_chrome(self : Daemon, wait_for_url : Bool) -> Unit {
  let chrome_path = find_chrome()
  guard chrome_path != "" else {
    fail("Chrome executable not found; set CHROME_BIN")
  }
  let group = match self.group {
    Some(group) => group
    None => fail("mapled task group is unavailable")
  }
  let deadline = now_ms() + (if wait_for_url { 30000.0 } else { 20000.0 })
  let mut url_ready = false
  let mut last_error = "URL is unavailable: \{self.game_url}"
  for ;; {
    try @async.with_timeout(1000, () => @http.get(self.game_url)) catch {
      error => last_error = error.to_string()
    } noraise {
      (response, _) => if response.code < 400 { url_ready = true }
    }
    if url_ready {
      break
    }
    if !wait_for_url || now_ms() >= deadline {
      break
    }
    @async.sleep(250)
  }
  guard url_ready else {
    fail(
      "URL did not become ready: \{self.game_url}; last error: \{last_error}",
    )
  }
  let list_url = "http://127.0.0.1:\{self.cdp_port}/json/list"
  let mut target : String? = None
  try @async.with_timeout(1000, () => @http.get(list_url)) catch {
    error => last_error = error.to_string()
  } noraise {
    (_, body) =>
      try body.json() catch {
        error => last_error = error.to_string()
      } noraise {
        pages =>
          target = @mapled_protocol.select_cdp_target(pages, self.game_url)
      }
  }
  if target is None {
    let new_url = "http://127.0.0.1:\{self.cdp_port}/json/new?\{encode_uri_component(self.game_url)}"
    try @async.with_timeout(1000, () => @http.put(new_url, b"")) catch {
      error => last_error = error.to_string()
    } noraise {
      (_, body) =>
        try body.json() catch {
          error => last_error = error.to_string()
        } noraise {
          { "webSocketDebuggerUrl": String(url), .. } => target = Some(url)
          _ => last_error = "CDP /json/new returned no WebSocket target"
        }
    }
  }
  if target is None {
    if !@fs.exists(self.user_data_dir) {
      @fs.mkdir(self.user_data_dir, permission=0o700, recursive=true)
    }
    if !@fs.exists("logs") {
      @fs.mkdir("logs", permission=0o755, recursive=true)
    }
    let chrome_output = @process.redirect_to_file(
      "logs/chrome.log",
      append=true,
      create_mode=OpenOrCreate,
      permission=0o600,
    )
    let spawned = @process.spawn(
      group,
      chrome_path,
      [
        "--remote-debugging-port=\{self.cdp_port}",
        "--user-data-dir=\{self.user_data_dir}",
        "--disable-background-timer-throttling",
        "--disable-renderer-backgrounding",
        "--enable-unsafe-webgpu",
        self.game_url,
      ],
      stdout=chrome_output,
      stderr=chrome_output,
      no_wait=true,
    )
    self.chrome = Some(spawned)
    group.spawn_bg(allow_failure=true, () => {
      let code = spawned.wait()
      self.chrome = None
      if !self.finished {
        self.push_log(
          "warning",
          "mapled",
          "Chrome exited code=\{code}; run maple open to reconnect",
        )
      }
    })
  }
  while target is None && now_ms() < deadline {
    try @async.with_timeout(1000, () => @http.get(list_url)) catch {
      error => last_error = error.to_string()
    } noraise {
      (_, body) =>
        try body.json() catch {
          error => last_error = error.to_string()
        } noraise {
          pages =>
            target = @mapled_protocol.select_cdp_target(pages, self.game_url)
        }
    }
    if target is None && now_ms() < deadline {
      @async.sleep(250)
    }
  }
  let target = match target {
    Some(target) => target
    None =>
      fail(
        "No CDP page target found on port \{self.cdp_port}; last error: \{last_error}",
      )
  }
  let socket = open_cdp(
    target,
    group,
    message => self.handle_cdp_event(message),
    () => {
      self.cdp = None
      if !self.finished {
        self.push_log(
          "warning", "cdp", "browser disconnected; run maple open to reconnect",
        )
      }
    },
  )
  self.cdp = Some(socket)
  ignore(self.send_cdp("Runtime.enable", Json::empty_object()))
  ignore(self.send_cdp("Log.enable", Json::empty_object()))
  ignore(self.send_cdp("Network.enable", Json::empty_object()))
  ignore(self.send_cdp("Page.enable", Json::empty_object()))
}

///|
async fn Daemon::handle(self : Daemon, request : Json) -> Json {
  guard request is { "action": String(action), .. } else {
    fail("request action is required")
  }
  if action == "status" {
    let console_ready = try
      self.evaluate("typeof globalThis.$console", false)
    catch {
      _ => false
    } noraise {
      String("object") => true
      _ => false
    }
    let connected = self.cdp is Some(cdp) && cdp.open
    return {
      "ok": true,
      "url": self.game_url,
      "cdpPort": self.cdp_port,
      "browserConnected": connected,
      "consoleReady": console_ready,
      "logCount": self.logs.length(),
      "networkCount": self.request_order.length(),
    }
  }
  if action == "open" || action == "open-wait" {
    if self.cdp is Some(cdp) && cdp.open {
      return { "ok": true, "message": "browser already connected" }
    }
    if request is { "gameUrl": String(game_url), .. } && game_url != "" {
      self.game_url = game_url
    }
    if action == "open" {
      if self.chrome_connecting {
        return { "ok": true, "message": "browser open already requested" }
      }
      let group = match self.group {
        Some(group) => group
        None => fail("mapled task group is unavailable")
      }
      self.chrome_connecting = true
      self.chrome_connection_error = None
      group.spawn_bg(allow_failure=true, () => {
        self.connect_chrome(false) catch {
          error => {
            self.chrome_connection_error = Some(error.to_string())
            self.push_log("error", "mapled", error.to_string())
          }
        }
        self.chrome_connecting = false
      })
      return { "ok": true, "message": "browser open requested" }
    }
    if self.chrome_connecting {
      let deadline = now_ms() + 30000.0
      while self.chrome_connecting && now_ms() < deadline {
        if self.cdp is Some(cdp) && cdp.open {
          return { "ok": true, "message": "browser opened" }
        }
        @async.sleep(50)
      }
      if self.cdp is Some(cdp) && cdp.open {
        return { "ok": true, "message": "browser opened" }
      }
      fail(
        self.chrome_connection_error.unwrap_or(
          "browser connection did not complete before timeout",
        ),
      )
    }
    self.chrome_connecting = true
    self.chrome_connection_error = None
    self.connect_chrome(true) catch {
      error => {
        self.chrome_connecting = false
        self.chrome_connection_error = Some(error.to_string())
        raise error
      }
    }
    self.chrome_connecting = false
    return { "ok": true, "message": "browser opened" }
  }
  if action == "logs-clear" {
    self.logs.clear()
    return { "ok": true, "message": "browser logs cleared" }
  }
  if action == "cmd" {
    guard self.evaluate("typeof globalThis.$console", false) is String("object") else {
      fail("globalThis.$console is not ready; run `maple wait-ready`")
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
    return { "ok": true, "result": self.evaluate(expression, true) }
  }
  if action == "eval" {
    let expression = match request {
      { "expression": String(value), .. } => value
      _ => ""
    }
    return { "ok": true, "result": self.evaluate(expression, true) }
  }
  if action == "logs" {
    let wanted = match request {
      { "level": String(value), .. } => value
      _ => ""
    }
    let logs = self.logs.filter(entry => wanted == "" || entry.level == wanted)
    let start = if logs.length() > 200 { logs.length() - 200 } else { 0 }
    return {
      "ok": true,
      "logs": logs.view(start~).map(entry => ToJson::to_json(entry)),
    }
  }
  if action == "network" {
    let failed_only = request is { "failed": True, .. }
    let entries = [
      for id in self.request_order if self.requests.get(id) is Some(entry) &&
      (
        !failed_only ||
        entry.failed == Some(true) ||
        entry.status.unwrap_or(0) >= 400
      ) => entry
    ]
    let start = if entries.length() > 200 { entries.length() - 200 } else { 0 }
    return {
      "ok": true,
      "entries": entries.view(start~).map(entry => ToJson::to_json(entry)),
    }
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
    return { "ok": true, "out": out }
  }
  if action == "reload" {
    ignore(self.send_cdp("Page.reload", { "ignoreCache": true }))
    return { "ok": true, "message": "reload requested" }
  }
  if action == "bot-run" {
    return self.run_bot(request)
  }
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
      if console_ready {
        break
      }
      @async.sleep(250)
    }
    guard console_ready else {
      fail("globalThis.$console was not installed before timeout")
    }
    let mut state = Json::null()
    for _ in 0..<90 {
      let value = self.evaluate(
        "globalThis.$console.render_game_to_text()", true,
      )
      state = match value {
        String(text) => @json.parse(text)
        value => value
      }
      if state is { "phase": "GameActive", .. } {
        break
      }
      ignore(self.evaluate("globalThis.$console.step(10)", true))
    }
    if state is { "phase": "GameActive", .. } {
      let response : Map[String, Json] = { "ok": true, "phase": "GameActive" }
      if state is { "map_id": map_id, .. } {
        response["map_id"] = map_id
      }
      return Json::object(response)
    }
    let phase = match state {
      { "phase": String(value), .. } => value
      _ => "unknown"
    }
    return {
      "ok": false,
      "error": "game not active after waiting; current phase=\{phase}",
    }
  }
  if action == "close" {
    return { "ok": true, "message": "close requested" }
  }
  { "ok": false, "error": "unknown action: \{action}" }
}

///|
async fn Daemon::serve_connection(self : Daemon, socket : @socket.Tcp) -> Unit {
  guard socket.read_until("\n") is Some(line) else { return }
  let request = @json.parse(line) catch {
    err => {
      self.push_log("error", "mapled", err.to_string())
      let response : Json = { "ok": false, "error": err.to_string() }
      socket.write(response.stringify() + "\n")
      return
    }
  }
  guard request is { "token": String(token), .. } && token == self.token else {
    socket.write(
      ({ "ok": false, "error": "invalid capability token" } : Json).stringify() +
      "\n",
    )
    return
  }
  if request is { "action": "logs-follow", .. } {
    for entry in self.logs {
      let event : Json = { "event": "log", "entry": ToJson::to_json(entry) }
      socket.write(event.stringify() + "\n")
    }
    let subscriber = LogSubscriber::{
      id: self.next_subscriber_id,
      queue: @async.Queue(kind=DiscardOldest(1024)),
    }
    self.next_subscriber_id += 1
    self.subscribers.push(subscriber)
    defer (for index, current in self.subscribers {
      if current.id == subscriber.id {
        ignore(self.subscribers.remove(index))
        break
      }
    })
    for ;; {
      let line = subscriber.queue.get()
      socket.write(line)
    }
    return
  }
  let response = self.handle(request) catch {
    error => {
      self.push_log("error", "mapled", error.to_string())
      ({ "ok": false, "error": error.to_string() } : Json)
    }
  }
  if request is { "action": "close", .. } {
    self.shutdown()
  }
  socket.write(response.stringify() + "\n")
  if request is { "action": "close", .. } {
    self.stop.put("mapled stopped")
  }
}

///|
async fn Daemon::shutdown(self : Daemon) -> Unit {
  guard !self.finished else { return }
  self.finished = true
  if self.server is Some(server) {
    server.close()
    self.server = None
  }
  if self.cdp is Some(cdp) {
    cdp.close()
    self.cdp = None
  }
  if self.chrome is Some(chrome) {
    chrome.cancel()
    self.chrome = None
  }
  self.subscribers.clear()
  self.group = None
  remove_path(self.state_path)
}

///|
async fn Daemon::run(self : Daemon) -> String {
  @signal.set_global_cancellation_signals([SIGINT, SIGTERM, SIGHUP])
  let token_bytes = FixedArray::make(32, b'\x00')
  fill_secure_random(token_bytes, token_bytes.length())
  self.token = @base64.encode(
      token_bytes.unsafe_reinterpret_as_bytes(),
      padding=false,
    )
    .replace_all(old="+", new="-")
    .replace_all(old="/", new="_")
  let server = @socket.TcpServer::TcpServer(
    @socket.Addr::parse("127.0.0.1:39933"),
    reuse_addr=true,
  )
  self.server = Some(server)
  @async.with_task_group(group => {
    self.group = Some(group)
    group.add_defer(() => {
      @async.protect_from_cancel(resume_on_cancel=true, () => self.shutdown())
    })
    group.spawn_bg(() => {
      server.run_forever((socket, _) => self.serve_connection(socket))
    })
    self.write_state("ready")
    self.push_log("info", "mapled", "listening on 127.0.0.1:39933")
    let message = self.stop.get()
    group.return_immediately(message)
    message
  })
}
