///|
extern "js" fn run_maple_cli(
  action : String,
  cdp_port : String,
  game_url : String,
  command : String,
  args : Array[String],
  expression : String,
  level : String,
  failed : Bool,
  out : String,
  frames : String,
) -> @js_async.Promise[String] =
  #| (
  #|   action,
  #|   cdpPort,
  #|   gameUrl,
  #|   command,
  #|   args,
  #|   expression,
  #|   level,
  #|   failed,
  #|   out,
  #|   frames
  #| ) => (async () => {
  #|   const childProcess = require("node:child_process");
  #|   const fs = require("node:fs");
  #|   const net = require("node:net");
  #|   const os = require("node:os");
  #|   const path = require("node:path");
  #|   const socketPath = path.join(os.tmpdir(), "maple-moon-mapled.sock");
  #|   const statePath = path.join(os.tmpdir(), "maple-moon-mapled.state.json");
  #|   const pidPath = path.join(os.tmpdir(), "maple-moon-mapled.pid");
  #|   const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  #|   const isPidAlive = (pid) => {
  #|     if (!Number.isInteger(pid) || pid <= 0) return false;
  #|     try {
  #|       process.kill(pid, 0);
  #|       return true;
  #|     } catch (_) {
  #|       return false;
  #|     }
  #|   };
  #|   const readState = () => {
  #|     try {
  #|       return JSON.parse(fs.readFileSync(statePath, "utf8"));
  #|     } catch (_) {
  #|       return null;
  #|     }
  #|   };
  #|   const cleanStaleFiles = () => {
  #|     const state = readState();
  #|     const pid = Number.parseInt(fs.existsSync(pidPath) ? fs.readFileSync(pidPath, "utf8") : String(state?.pid ?? ""), 10);
  #|     if (!isPidAlive(pid)) {
  #|       for (const file of [socketPath, statePath, pidPath]) {
  #|         try { fs.rmSync(file, { force: true }); } catch (_) {}
  #|       }
  #|     }
  #|   };
  #|   const request = (message, timeoutMs = 30000) => new Promise((resolve, reject) => {
  #|     const socket = net.createConnection(socketPath);
  #|     let buffer = "";
  #|     let settled = false;
  #|     const timer = setTimeout(() => {
  #|       if (settled) return;
  #|       settled = true;
  #|       socket.destroy();
  #|       reject(new Error(`mapled request timed out after ${timeoutMs}ms`));
  #|     }, timeoutMs);
  #|     socket.setEncoding("utf8");
  #|     socket.on("connect", () => socket.write(`${JSON.stringify(message)}\n`));
  #|     socket.on("data", (chunk) => {
  #|       buffer += chunk;
  #|       const newline = buffer.indexOf("\n");
  #|       if (newline < 0 || settled) return;
  #|       settled = true;
  #|       clearTimeout(timer);
  #|       socket.end();
  #|       try {
  #|         const response = JSON.parse(buffer.slice(0, newline));
  #|         if (response.ok === false) reject(new Error(response.error || "mapled request failed"));
  #|         else resolve(response);
  #|       } catch (error) {
  #|         reject(error);
  #|       }
  #|     });
  #|     socket.on("error", (error) => {
  #|       if (settled) return;
  #|       settled = true;
  #|       clearTimeout(timer);
  #|       reject(error);
  #|     });
  #|   });
  #|   const format = (response) => {
  #|     if (action === "logs") {
  #|       const logs = response.logs || [];
  #|       if (logs.length === 0) return "(no logs)";
  #|       return logs.map((entry) => {
  #|         const time = new Date(entry.time).toISOString().slice(11, 23);
  #|         return `[${time}] ${entry.level} ${entry.source}: ${entry.text}`;
  #|       }).join("\n");
  #|     }
  #|     if (action === "network") {
  #|       const entries = response.entries || [];
  #|       if (entries.length === 0) return "(no network entries)";
  #|       return entries.map((entry) => {
  #|         const status = entry.failed ? "FAIL" : String(entry.status ?? "...");
  #|         const kind = String(entry.type ?? "").padEnd(10, " ");
  #|         const size = entry.size == null ? "" : `${entry.size}B`;
  #|         const ms = entry.duration_ms == null ? "" : `${entry.duration_ms}ms`;
  #|         return `${status.padEnd(5, " ")} ${kind} ${size.padStart(9, " ")} ${ms.padStart(8, " ")} ${entry.url}`;
  #|       }).join("\n");
  #|     }
  #|     return JSON.stringify(response, null, 2);
  #|   };
  #|   const payload = { action, cdpPort, gameUrl, command, args, expression, level, failed, out, frames };
  #|   if (action === "bot-run") {
  #|     const debugUrl = String(gameUrl || "http://localhost:8080/game_debug.html");
  #|     const port = String(cdpPort || "9333");
  #|     const timeoutMs = Math.max(1, Number.parseInt(String(frames || "120000"), 10) || 120000);
  #|     const scriptPath = path.resolve(String(command || ""));
  #|     if (!fs.existsSync(scriptPath)) throw new Error(`playtest script not found: ${scriptPath}`);
  #|     let buildOutput = "";
  #|     try {
  #|       buildOutput = childProcess.execFileSync("moon", [
  #|         "build",
  #|         "--target",
  #|         "js",
  #|         "--release",
  #|         "src/apps/game_debug",
  #|       ], { cwd: process.cwd(), encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  #|     } catch (error) {
  #|       const stderr = error.stderr ? String(error.stderr) : "";
  #|       const stdout = error.stdout ? String(error.stdout) : "";
  #|       throw new Error(`game_debug build failed\n${stdout}${stderr}`);
  #|     }
  #|     try {
  #|       const existing = await request({ action: "status" }, 1500);
  #|       if (String(existing.cdpPort) !== port || String(existing.url) !== debugUrl) {
  #|         throw new Error("mapled is already running with different config; run `maple close` first");
  #|       }
  #|     } catch (error) {
  #|       if (String(error.message || "").includes("different config")) throw error;
  #|       cleanStaleFiles();
  #|       const child = childProcess.spawn("moon", [
  #|         "run",
  #|         "--target",
  #|         "js",
  #|         "src/cmd/mapled",
  #|         "--cdp-port",
  #|         port,
  #|         "--url",
  #|         debugUrl,
  #|       ], { cwd: process.cwd(), detached: true, stdio: "ignore" });
  #|       child.unref();
  #|       let lastError = "mapled did not become ready";
  #|       for (let i = 0; i < 100; i += 1) {
  #|         await sleep(250);
  #|         const state = readState();
  #|         if (state?.phase === "failed" || state?.phase === "stopped") {
  #|           throw new Error(`mapled startup failed: phase=${state.phase}`);
  #|         }
  #|         try {
  #|           await request({ action: "status" }, 1500);
  #|           break;
  #|         } catch (e) {
  #|           lastError = e.message;
  #|           if (i === 99) throw new Error(lastError);
  #|         }
  #|       }
  #|     }
  #|     const script = fs.readFileSync(scriptPath, "utf8");
  #|     const response = await request({
  #|       action: "bot-run",
  #|       scriptPath,
  #|       script,
  #|       timeoutMs,
  #|       buildOutput,
  #|     }, timeoutMs + 60000);
  #|     const formatted = format(response);
  #|     if (response.passed === false) throw new Error(formatted);
  #|     return formatted;
  #|   }
  #|   if (action === "start") {
  #|     try {
  #|       const existing = await request({ action: "status" }, 1500);
  #|       if (String(existing.cdpPort) !== String(cdpPort || "9333") || String(existing.url) !== String(gameUrl || "http://localhost:8080")) {
  #|         throw new Error("mapled is already running with different config; run `maple close` first");
  #|       }
  #|       return format({ ok: true, message: "mapled already running", status: existing });
  #|     } catch (error) {
  #|       if (String(error.message || "").includes("different config")) throw error;
  #|       cleanStaleFiles();
  #|       const child = childProcess.spawn("moon", [
  #|         "run",
  #|         "--target",
  #|         "js",
  #|         "src/cmd/mapled",
  #|         "--cdp-port",
  #|         String(cdpPort || "9333"),
  #|         "--url",
  #|         String(gameUrl || "http://localhost:8080"),
  #|       ], { cwd: process.cwd(), detached: true, stdio: "ignore" });
  #|       child.unref();
  #|       let lastError = "mapled did not become ready";
  #|       for (let i = 0; i < 100; i += 1) {
  #|         await sleep(250);
  #|         const state = readState();
  #|         if (state?.phase === "failed" || state?.phase === "stopped") {
  #|           throw new Error(`mapled startup failed: phase=${state.phase}`);
  #|         }
  #|         try {
  #|           const status = await request({ action: "status" }, 1500);
  #|           return format({ ok: true, message: "mapled started", status });
  #|         } catch (e) {
  #|           lastError = e.message;
  #|         }
  #|       }
  #|       throw new Error(lastError);
  #|     }
  #|   }
  #|   if (action === "close") {
  #|     const state = readState();
  #|     let response = null;
  #|     try {
  #|       response = await request(payload, 10000);
  #|     } catch (error) {
  #|       cleanStaleFiles();
  #|       throw error;
  #|     }
  #|     const pid = Number.parseInt(String(state?.pid ?? response.pid ?? ""), 10);
  #|     for (let i = 0; i < 100; i += 1) {
  #|       if (!fs.existsSync(socketPath) && !isPidAlive(pid)) break;
  #|       await sleep(100);
  #|     }
  #|     cleanStaleFiles();
  #|     return format(response);
  #|   }
  #|   const timeoutMs = 30000;
  #|   return format(await request(payload, timeoutMs));
  #| })()

///|
extern "js" fn program_args() -> Array[String] =
  #| () => process.argv.slice(2)

///|
extern "js" fn write_stderr(message : String) -> Unit =
  #| (message) => process.stderr.write(message)

///|
extern "js" fn exit(code : Int) -> Unit =
  #| (code) => process.exit(code)

///|
async fn main {
  let root = @argparse.Command(
    "maple",
    about="Maple Moon browser debugging CLI",
    subcommand_required=true,
    subcommands=[
      @argparse.Command(
        "start",
        about="Start mapled and open the game in Chrome",
        options=[
          @argparse.OptionArg("cdp-port", default_values=["9333"]),
          @argparse.OptionArg("url", default_values=["http://localhost:8080"]),
        ],
      ),
      @argparse.Command("cmd", about="Execute a registered $console command", positionals=[
        @argparse.PositionArg("name"),
        @argparse.PositionArg("args", num_args=@argparse.ValueRange(lower=0)),
      ]),
      @argparse.Command("eval", about="Evaluate JavaScript in the game page", positionals=[
        @argparse.PositionArg("expression"),
      ]),
      @argparse.Command("logs", about="Print collected browser logs", options=[
        @argparse.OptionArg("level", default_values=[""]),
      ]),
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
      @argparse.Command("status", about="Show daemon status"),
      @argparse.Command("close", about="Close daemon and browser"),
    ],
  )
  let parsed = root.parse(argv=program_args()) catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(2)
      return
    }
  }
  let output = try {
    match parsed.subcommand {
      Some(("start", child)) => {
        let cdp_port = match child.values.get("cdp-port") {
          Some(values) => values[0]
          None => "9333"
        }
        let game_url = match child.values.get("url") {
          Some(values) => values[0]
          None => "http://localhost:8080"
        }
        run_maple_cli(
          "start",
          cdp_port,
          game_url,
          "",
          [],
          "",
          "",
          false,
          "",
          "",
        ).wait()
      }
      Some(("cmd", child)) => {
        let name = match child.values.get("name") {
          Some(values) => values[0]
          None => ""
        }
        let args = match child.values.get("args") {
          Some(values) => values
          None => []
        }
        run_maple_cli("cmd", "", "", name, args, "", "", false, "", "").wait()
      }
      Some(("eval", child)) => {
        let expression = match child.values.get("expression") {
          Some(values) => values[0]
          None => ""
        }
        run_maple_cli("eval", "", "", "", [], expression, "", false, "", "").wait()
      }
      Some(("logs", child)) => {
        let level = match child.values.get("level") {
          Some(values) => values[0]
          None => ""
        }
        run_maple_cli("logs", "", "", "", [], "", level, false, "", "").wait()
      }
      Some(("network", child)) => {
        let failed = match child.flags.get("failed") {
          Some(value) => value
          None => false
        }
        run_maple_cli("network", "", "", "", [], "", "", failed, "", "").wait()
      }
      Some(("screenshot", child)) => {
        let out = match child.values.get("out") {
          Some(values) => values[0]
          None => "screenshot.png"
        }
        run_maple_cli("screenshot", "", "", "", [], "", "", false, out, "").wait()
      }
      Some(("wait-ready", _)) =>
        run_maple_cli("wait-ready", "", "", "", [], "", "", false, "", "").wait()
      Some(("bot", child)) =>
        match child.subcommand {
          Some(("run", run_child)) => {
            let script = match run_child.values.get("script") {
              Some(values) => values[0]
              None => ""
            }
            let cdp_port = match run_child.values.get("cdp-port") {
              Some(values) => values[0]
              None => "9333"
            }
            let game_url = match run_child.values.get("url") {
              Some(values) => values[0]
              None => "http://localhost:8080/game_debug.html"
            }
            let timeout_ms = match run_child.values.get("timeout-ms") {
              Some(values) => values[0]
              None => "120000"
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
            ).wait()
          }
          _ => {
            println(root.render_help())
            return
          }
        }
      Some(("reload", _)) =>
        run_maple_cli("reload", "", "", "", [], "", "", false, "", "").wait()
      Some(("status", _)) =>
        run_maple_cli("status", "", "", "", [], "", "", false, "", "").wait()
      Some(("close", _)) =>
        run_maple_cli("close", "", "", "", [], "", "", false, "", "").wait()
      _ => {
        println(root.render_help())
        return
      }
    }
  } catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(1)
      return
    }
  }
  println(output)
}
