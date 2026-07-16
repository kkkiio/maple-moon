///|
struct DaemonConnection {
  port : Int
  token : String
}

///|
async fn load_daemon_connection() -> DaemonConnection {
  let temp_dir = @env.get_env_var("TMPDIR").unwrap_or("/tmp")
  let state_path = @path.Path(temp_dir)
    .join(@path.Path("maple-moon-mapled.state.json"))
    .to_string()
  guard @fs.exists(state_path) else { fail("mapled is not running") }
  let state = @fs.read_file(state_path).json()
  guard state
    is {
      "phase": "ready",
      "endpoint": { "host": "127.0.0.1", "port": Number(port, ..), .. },
      "token": String(token),
      ..
    } &&
    token != "" else {
    fail("mapled state is invalid")
  }
  let port = port.to_int()
  guard port > 0 && port < 65536 else { fail("mapled endpoint is invalid") }
  { port, token }
}

///|
async fn request(message : Json, timeout_ms? : Int = 30000) -> Json {
  let connection = load_daemon_connection()
  @async.with_timeout(timeout_ms, () => {
    let socket = @socket.Tcp::connect(
      @socket.Addr::parse("127.0.0.1:\{connection.port}"),
    )
    defer socket.close()
    guard message is Object(fields) else {
      fail("mapled request must be a JSON object")
    }
    fields["token"] = Json::string(connection.token)
    socket.write(message.stringify() + "\n")
    guard socket.read_until("\n") is Some(line) else {
      fail("mapled closed the connection without a response")
    }
    let response = @json.parse(line)
    if response is { "ok": False, "error": String(error), .. } {
      fail(error)
    }
    response
  })
}

///|
fn format_response(action : String, response : Json) -> String {
  if action == "logs" {
    guard response is { "logs": Array(logs), .. } else { return "(no logs)" }
    if logs.is_empty() {
      return "(no logs)"
    }
    return logs
      .map(entry => {
        let time = match entry {
          { "time": Number(value, ..), .. } => value.to_int64().to_string()
          _ => "?"
        }
        let level = match entry {
          { "level": String(value), .. } => value
          _ => "unknown"
        }
        let source = match entry {
          { "source": String(value), .. } => value
          _ => "unknown"
        }
        let text = match entry {
          { "text": String(value), .. } => value
          _ => ""
        }
        "[\{time}] \{level} \{source}: \{text}"
      })
      .join("\n")
  }
  if action == "network" {
    guard response is { "entries": Array(entries), .. } else {
      return "(no network entries)"
    }
    if entries.is_empty() {
      return "(no network entries)"
    }
    return entries
      .map(entry => {
        let status = match entry {
          { "failed": True, .. } => "FAIL"
          { "status": Number(value, ..), .. } => value.to_int().to_string()
          _ => "..."
        }
        let kind = match entry {
          { "type": String(value), .. } => value
          _ => ""
        }
        let size = match entry {
          { "size": Number(value, ..), .. } => "\{value}B"
          _ => ""
        }
        let duration = match entry {
          { "duration_ms": Number(value, ..), .. } => "\{value}ms"
          _ => ""
        }
        let url = match entry {
          { "url": String(value), .. } => value
          _ => ""
        }
        "\{status.pad_end(5, ' ')} \{kind.pad_end(10, ' ')} \{size.pad_start(9, ' ')} \{duration.pad_start(8, ' ')} \{url}"
      })
      .join("\n")
  }
  response.stringify(indent=2)
}

///|
async fn follow_logs(out : String) -> String {
  let connection = load_daemon_connection()
  let socket = @socket.Tcp::connect(
    @socket.Addr::parse("127.0.0.1:\{connection.port}"),
  )
  defer socket.close()
  let destination = @path.Path(out).resolve()
  let parent = destination.dirname().to_string()
  if parent != "" && !@fs.exists(parent) {
    @fs.mkdir(parent, permission=0o755, recursive=true)
  }
  let file = @fs.open(
    destination.to_string(),
    mode=WriteOnly,
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
  defer file.close()
  let request : Json = { "action": "logs-follow", "token": connection.token }
  socket.write(request.stringify() + "\n")
  while socket.read_until("\n") is Some(line) {
    let message = @json.parse(line)
    guard message is { "event": "log", "entry": entry, .. } else { continue }
    let time = match entry {
      { "time": Number(value, ..), .. } => value.to_int64().to_string()
      _ => "?"
    }
    let level = match entry {
      { "level": String(value), .. } => value
      _ => "unknown"
    }
    let source = match entry {
      { "source": String(value), .. } => value
      _ => "unknown"
    }
    let text = match entry {
      { "text": String(value), .. } => value
      _ => ""
    }
    let location = match entry {
      { "url": String(url), "line": Number(line, ..), .. } =>
        " \{url}:\{line.to_int() + 1}"
      { "url": String(url), .. } => " \{url}"
      _ => ""
    }
    let formatted = "[\{time}] \{level} \{source}: \{text}\{location}\n"
    @stdio.stdout.write("[browser] " + formatted)
    file.write(formatted)
  }
  "browser log stream closed"
}

///|
async fn ensure_daemon(
  cdp_port : String,
  game_url : String,
  require_url_match : Bool,
  wait_ready : Bool,
) -> Json {
  let expected_port = if cdp_port == "" { "9333" } else { cdp_port }
  let expected_url = if game_url == "" {
    "http://localhost:8080"
  } else {
    game_url
  }
  try request({ "action": "status" }, timeout_ms=1500) catch {
    _ => {
      if !@fs.exists("logs") {
        @fs.mkdir("logs", permission=0o755, recursive=true)
      }
      let (build_code, build_stdout, build_stderr) = @process.collect_output(
        "moon",
        ["build", "--target", "native", "src/cmd/mapled"],
      )
      guard build_code == 0 else {
        fail(
          "mapled build failed\n\{build_stdout.text()}\{build_stderr.text()}",
        )
      }
      let daemon_executable = @path.Path(
          "_build/native/debug/build/KKKIIO/maple-moon/cmd/mapled/mapled.exe",
        )
        .resolve()
        .to_string()
      guard @fs.exists(daemon_executable) else {
        fail("mapled executable not found: \{daemon_executable}")
      }
      spawn_detached_mapled(
        daemon_executable,
        @path.Path("logs/mapled.log").resolve().to_string(),
        expected_port,
        expected_url,
      )
      if !wait_ready {
        return {
          "ok": true,
          "starting": true,
          "cdpPort": expected_port,
          "url": expected_url,
        }
      }
      let mut last_error = "mapled did not become ready"
      let deadline = @env.now().to_double() + 30000.0
      while @env.now().to_double() < deadline {
        try request({ "action": "status" }, timeout_ms=1000) catch {
          error => {
            last_error = error.to_string()
            @async.sleep(250)
          }
        } noraise {
          status => {
            guard status is { "cdpPort": Number(actual_port, ..), .. } &&
              actual_port.to_int().to_string() == expected_port else {
              fail(
                "mapled is already running with different config; run `maple close` first",
              )
            }
            if require_url_match &&
              status
              is {
                "browserConnected": True,
                "url": String(actual_url),
                ..
              } &&
              actual_url != expected_url {
              fail(
                "mapled is already running with different config; run `maple close` first",
              )
            }
            return status
          }
        }
      }
      fail(last_error)
    }
  } noraise {
    status => {
      guard status is { "cdpPort": Number(actual_port, ..), .. } &&
        actual_port.to_int().to_string() == expected_port else {
        fail(
          "mapled is already running with different config; run `maple close` first",
        )
      }
      if require_url_match &&
        status is { "browserConnected": True, "url": String(actual_url), .. } &&
        actual_url != expected_url {
        fail(
          "mapled is already running with different config; run `maple close` first",
        )
      }
      status
    }
  }
}

///|
async fn run_maple_cli(
  action : String,
  cdp_port : String,
  game_url : String,
  command : String,
  args : Array[String],
  expression : String,
  level : String,
  failed : Bool,
  out : String,
  timeout_text : String,
) -> String {
  if action == "logs-follow" {
    return follow_logs(if out == "" { "logs/browser.log" } else { out })
  }
  if action == "status-wait" {
    let mut last_error = "mapled did not become ready"
    let deadline = @env.now().to_double() + 30000.0
    while @env.now().to_double() < deadline {
      try request({ "action": "status" }, timeout_ms=1000) catch {
        error => {
          last_error = error.to_string()
          @async.sleep(250)
        }
      } noraise {
        response => return format_response("status", response)
      }
    }
    fail(last_error)
  }
  if action == "start" {
    let status = ensure_daemon(cdp_port, "", false, true)
    return format_response("start", {
      "ok": true,
      "message": "mapled started or reused",
      "status": status,
    })
  }
  if action == "bot-run" {
    let script_path = @path.Path(command).resolve().to_string()
    guard @fs.exists(script_path) else {
      fail("playtest script not found: \{script_path}")
    }
    let (exit_code, stdout, stderr) = @process.collect_output("moon", [
      "build", "--target", "js", "--release", "src/apps/game_debug",
    ])
    guard exit_code == 0 else {
      fail("game_debug build failed\n\{stdout.text()}\{stderr.text()}")
    }
    let timeout_ms = @string.parse_int(timeout_text) catch {
      _ => fail("timeout-ms must be an integer between 1 and 2147000000")
    }
    guard timeout_ms > 0 && timeout_ms <= 2147000000 else {
      fail("timeout-ms must be between 1 and 2147000000")
    }
    ignore(ensure_daemon(cdp_port, game_url, true, true))
    ignore(
      request({ "action": "open-wait", "gameUrl": game_url }, timeout_ms=35000),
    )
    let response = request(
      {
        "action": "bot-run",
        "scriptPath": script_path,
        "script": @fs.read_file(script_path).text(),
        "timeoutMs": timeout_ms,
        "buildOutput": stdout.text(),
      },
      timeout_ms=timeout_ms + 60000,
    )
    let formatted = format_response(action, response)
    if response is { "passed": False, .. } {
      fail(formatted)
    }
    return formatted
  }
  if action == "close" {
    let response = request({ "action": "close" }) catch {
      _ => ({ "ok": true, "message": "mapled is not running" } : Json)
    }
    return format_response(action, response)
  }
  let payload : Json = {
    "action": action,
    "cdpPort": cdp_port,
    "gameUrl": game_url,
    "command": command,
    "args": args.map(value => Json::string(value)),
    "expression": expression,
    "level": level,
    "failed": failed,
    "out": out,
  }
  let timeout_ms = if action == "open-wait" { 35000 } else { 30000 }
  let response = request(payload, timeout_ms~)
  format_response(action, response)
}

///|
async fn main {
  @signal.set_global_cancellation_signals([SIGINT, SIGTERM, SIGHUP])
  let root = @argparse.Command(
    "maple",
    about="Maple Moon browser debugging CLI",
    subcommand_required=true,
    subcommands=[
      @argparse.Command("start", about="Start or reuse mapled", options=[
        @argparse.OptionArg("cdp-port", default_values=["9333"]),
      ]),
      @argparse.Command(
        "open",
        about="Open or reconnect the controlled Chrome",
        options=[
          @argparse.OptionArg("url", default_values=["http://localhost:8080"]),
        ],
        flags=[@argparse.FlagArg("wait")],
      ),
      @argparse.Command("cmd", about="Execute a registered $console command", positionals=[
        @argparse.PositionArg("name"),
        @argparse.PositionArg("args", num_args=@argparse.ValueRange(lower=0)),
      ]),
      @argparse.Command("eval", about="Evaluate JavaScript in the game page", positionals=[
        @argparse.PositionArg("expression"),
      ]),
      @argparse.Command(
        "logs",
        about="Read or follow collected browser logs",
        options=[
          @argparse.OptionArg("level", default_values=[""]),
          @argparse.OptionArg("out", default_values=["logs/browser.log"]),
        ],
        flags=[@argparse.FlagArg("clear"), @argparse.FlagArg("follow")],
      ),
      @argparse.Command("network", about="Print collected network requests", flags=[
        @argparse.FlagArg("failed"),
      ]),
      @argparse.Command("screenshot", about="Capture the game page", options=[
        @argparse.OptionArg("out", default_values=["screenshot.png"]),
      ]),
      @argparse.Command(
        "wait-ready",
        about="Wait for $console ready and GameActive phase",
      ),
      @argparse.Command(
        "bot",
        about="Run Playtest Bot scripts in the game_debug entrypoint",
        subcommand_required=true,
        subcommands=[
          @argparse.Command(
            "run",
            about="Run a JavaScript playtest script through mapled",
            options=[
              @argparse.OptionArg("cdp-port", default_values=["9333"]),
              @argparse.OptionArg("url", default_values=[
                "http://localhost:8080/game_debug.html",
              ]),
              @argparse.OptionArg("timeout-ms", default_values=["120000"]),
            ],
            positionals=[@argparse.PositionArg("script")],
          ),
        ],
      ),
      @argparse.Command("reload", about="Reload the game page"),
      @argparse.Command("status", about="Show daemon status", flags=[
        @argparse.FlagArg("wait"),
      ]),
      @argparse.Command("close", about="Close daemon and browser"),
    ],
  )
  let args = @env.args()[1:]
  if args.is_empty() {
    println(root.render_help())
    return
  }
  let parsed = root.parse(argv=args) catch {
    err => {
      @stdio.stderr.write(err.to_string() + "\n")
      @sys.exit(2)
      return
    }
  }
  let output = try {
    match parsed.subcommand {
      Some(("start", child)) => {
        let cdp_port = match child.values.get("cdp-port") {
          Some(values) | (None with values = ["9333"]) => values[0]
        }
        run_maple_cli("start", cdp_port, "", "", [], "", "", false, "", "")
      }
      Some(("open", child)) => {
        let game_url = match child.values.get("url") {
          Some(values) | (None with values = ["http://localhost:8080"]) =>
            values[0]
        }
        let wait = match child.flags.get("wait") {
          Some(value) | (None with value = false) => value
        }
        run_maple_cli(
          if wait {
            "open-wait"
          } else {
            "open"
          },
          "",
          game_url,
          "",
          [],
          "",
          "",
          false,
          "",
          "",
        )
      }
      Some(("cmd", child)) => {
        let name = match child.values.get("name") {
          Some(values) | (None with values = [""]) => values[0]
        }
        let values = match child.values.get("args") {
          Some(values) | (None with values = []) => values
        }
        run_maple_cli("cmd", "", "", name, values, "", "", false, "", "")
      }
      Some(("eval", child)) => {
        let expression = match child.values.get("expression") {
          Some(values) | (None with values = [""]) => values[0]
        }
        run_maple_cli("eval", "", "", "", [], expression, "", false, "", "")
      }
      Some(("logs", child)) => {
        let level = match child.values.get("level") {
          Some(values) | (None with values = [""]) => values[0]
        }
        let out = match child.values.get("out") {
          Some(values) | (None with values = ["logs/browser.log"]) => values[0]
        }
        let clear = match child.flags.get("clear") {
          Some(value) | (None with value = false) => value
        }
        let follow = match child.flags.get("follow") {
          Some(value) | (None with value = false) => value
        }
        let action = if clear {
          "logs-clear"
        } else if follow {
          "logs-follow"
        } else {
          "logs"
        }
        run_maple_cli(action, "", "", "", [], "", level, false, out, "")
      }
      Some(("network", child)) => {
        let failed = match child.flags.get("failed") {
          Some(value) | (None with value = false) => value
        }
        run_maple_cli("network", "", "", "", [], "", "", failed, "", "")
      }
      Some(("screenshot", child)) => {
        let out = match child.values.get("out") {
          Some(values) | (None with values = ["screenshot.png"]) => values[0]
        }
        run_maple_cli("screenshot", "", "", "", [], "", "", false, out, "")
      }
      Some(("wait-ready", _)) =>
        run_maple_cli("wait-ready", "", "", "", [], "", "", false, "", "")
      Some(("bot", child)) =>
        match child.subcommand {
          Some(("run", run_child)) => {
            let script = match run_child.values.get("script") {
              Some(values) | (None with values = [""]) => values[0]
            }
            let cdp_port = match run_child.values.get("cdp-port") {
              Some(values) | (None with values = ["9333"]) => values[0]
            }
            let game_url = match run_child.values.get("url") {
              Some(values)
              | (None with values = ["http://localhost:8080/game_debug.html"]) =>
                values[0]
            }
            let timeout_ms = match run_child.values.get("timeout-ms") {
              Some(values) | (None with values = ["120000"]) => values[0]
            }
            run_maple_cli(
              "bot-run",
              cdp_port,
              game_url,
              script,
              [],
              "",
              "",
              false,
              "",
              timeout_ms,
            )
          }
          _ => {
            println(root.render_help())
            return
          }
        }
      Some(("reload", _)) =>
        run_maple_cli("reload", "", "", "", [], "", "", false, "", "")
      Some(("status", child)) => {
        let wait = match child.flags.get("wait") {
          Some(value) | (None with value = false) => value
        }
        run_maple_cli(
          if wait {
            "status-wait"
          } else {
            "status"
          },
          "",
          "",
          "",
          [],
          "",
          "",
          false,
          "",
          "",
        )
      }
      Some(("close", _)) =>
        run_maple_cli("close", "", "", "", [], "", "", false, "", "")
      _ => {
        println(root.render_help())
        return
      }
    }
  } catch {
    error if @async.is_cancellation_error(error) => return
    err => {
      @stdio.stderr.write(err.to_string() + "\n")
      @sys.exit(1)
      return
    }
  }
  println(output)
}
