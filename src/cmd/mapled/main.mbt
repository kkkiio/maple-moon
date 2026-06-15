///|
extern "js" fn run_mapled(
  cdp_port : String,
  game_url : String,
) -> @js_async.Promise[String] =
  #| (cdpPortText, gameUrl) => (async () => {
  #|   const childProcess = require("node:child_process");
  #|   const fs = require("node:fs");
  #|   const net = require("node:net");
  #|   const os = require("node:os");
  #|   const path = require("node:path");
  #|   const cdpPort = Number.parseInt(String(cdpPortText || "9333"), 10);
  #|   if (!Number.isInteger(cdpPort) || cdpPort <= 0) throw new Error(`invalid CDP port: ${cdpPortText}`);
  #|   if (typeof WebSocket !== "function") throw new Error("Node native WebSocket is required");
  #|   gameUrl = String(gameUrl || "http://localhost:8080");
  #|   const socketPath = path.join(os.tmpdir(), "maple-moon-mapled.sock");
  #|   const statePath = path.join(os.tmpdir(), "maple-moon-mapled.state.json");
  #|   const pidPath = path.join(os.tmpdir(), "maple-moon-mapled.pid");
  #|   const userDataDir = path.join(os.tmpdir(), "maple-moon-chrome-profile");
  #|   const logs = [];
  #|   const requests = new Map();
  #|   const requestOrder = [];
  #|   const pending = new Map();
  #|   let nextId = 1;
  #|   let ws = null;
  #|   let chrome = null;
  #|   let server = null;
  #|   let finished = false;
  #|   let stopResolve = null;
  #|   const stopped = new Promise((resolve) => { stopResolve = resolve; });
  #|   const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  #|   const writeState = (phase) => {
  #|     const state = { phase, pid: process.pid, updated_at: Date.now() / 1000, config: { cdpPort, gameUrl } };
  #|     const tmp = `${statePath}.tmp`;
  #|     try {
  #|       fs.writeFileSync(tmp, JSON.stringify(state));
  #|       fs.renameSync(tmp, statePath);
  #|     } catch (_) {}
  #|   };
  #|   const removeOwnPid = () => {
  #|     try {
  #|       if (fs.readFileSync(pidPath, "utf8").trim() === String(process.pid)) fs.rmSync(pidPath, { force: true });
  #|     } catch (_) {}
  #|   };
  #|   const pushLog = (level, source, text, extra = {}) => {
  #|     logs.push({ time: Date.now(), level, source, text: String(text), ...extra });
  #|     while (logs.length > 1000) logs.shift();
  #|   };
  #|   const rememberRequest = (requestId, patch) => {
  #|     const entry = requests.get(requestId) || { requestId, start: Date.now() };
  #|     Object.assign(entry, patch);
  #|     requests.set(requestId, entry);
  #|     if (!requestOrder.includes(requestId)) requestOrder.push(requestId);
  #|     while (requestOrder.length > 500) {
  #|       const old = requestOrder.shift();
  #|       requests.delete(old);
  #|     }
  #|   };
  #|   const shutdown = (reason) => {
  #|     if (finished) return;
  #|     finished = true;
  #|     writeState(reason === "close requested" ? "stopped" : "failed");
  #|     try { server?.close(); } catch (_) {}
  #|     try { fs.rmSync(socketPath, { force: true }); } catch (_) {}
  #|     try { ws?.close(); } catch (_) {}
  #|     try { chrome?.kill(); } catch (_) {}
  #|     removeOwnPid();
  #|     stopResolve(reason === "close requested" ? "mapled stopped" : `mapled stopped: ${reason}`);
  #|   };
  #|   const sendCdp = (method, params = {}) => new Promise((resolve, reject) => {
  #|     if (!ws || ws.readyState !== WebSocket.OPEN) {
  #|       reject(new Error("CDP WebSocket is not connected"));
  #|       return;
  #|     }
  #|     const id = nextId++;
  #|     pending.set(id, { resolve, reject, method });
  #|     ws.send(JSON.stringify({ id, method, params }));
  #|   });
  #|   const evaluate = async (expression, awaitPromise = true) => {
  #|     const response = await sendCdp("Runtime.evaluate", { expression, awaitPromise, returnByValue: true, userGesture: true });
  #|     if (response.exceptionDetails) {
  #|       const detail = response.exceptionDetails;
  #|       throw new Error(detail.exception?.description || detail.text || "Runtime.evaluate failed");
  #|     }
  #|     if (Object.prototype.hasOwnProperty.call(response.result || {}, "value")) return response.result.value;
  #|     return response.result?.description ?? null;
  #|   };
  #|   const waitForConsole = async (timeoutMs) => {
  #|     const deadline = Date.now() + timeoutMs;
  #|     while (Date.now() < deadline) {
  #|       try {
  #|         if (await evaluate("typeof globalThis.$console", false) === "object") return;
  #|       } catch (_) {}
  #|       await sleep(250);
  #|     }
  #|     throw new Error("globalThis.$console was not installed before timeout");
  #|   };
  #|   const readGameState = async () => {
  #|     const stateText = await evaluate("globalThis.$console.render_game_to_text()");
  #|     return typeof stateText === "string" ? JSON.parse(stateText) : stateText;
  #|   };
  #|   const stepGame = async (frames) => {
  #|     await evaluate(`globalThis.$console.step(${Math.max(1, frames)})`);
  #|   };
  #|   const ensureGameActive = async () => {
  #|     let state = null;
  #|     let selectResult = null;
  #|     let createResult = null;
  #|     for (let i = 0; i < 90; i += 1) {
  #|       state = await readGameState();
  #|       if (state?.phase === "GameActive") {
  #|         return { createdCharacter: createResult != null, createResult, selectedCharacter: selectResult != null, selectResult, state };
  #|       }
  #|       if (state?.phase === "SelectCharacter" && selectResult == null) {
  #|         const result = await evaluate('globalThis.$console.cmd("select_char", "0")');
  #|         if (result?.ok || result?.code === "SELECT_CHAR_ALREADY_REQUESTED") {
  #|           selectResult = result;
  #|         } else if (result?.code === "INVALID_SLOT" && createResult == null) {
  #|           const created = await evaluate('globalThis.$console.cmd("new_character")');
  #|           if (created?.ok) createResult = created;
  #|         }
  #|       }
  #|       await stepGame(10);
  #|     }
  #|     throw new Error(`game did not enter GameActive; current phase=${state?.phase ?? "unknown"}`);
  #|   };
  #|   const handle = async (request) => {
  #|     const action = request.action;
  #|     if (action === "status") {
  #|       let consoleReady = false;
  #|       try { consoleReady = await evaluate("typeof globalThis.$console", false) === "object"; } catch (_) {}
  #|       return { ok: true, pid: process.pid, url: gameUrl, cdpPort, consoleReady, logCount: logs.length, networkCount: requestOrder.length };
  #|     }
  #|     if (action === "cmd") {
  #|       await waitForConsole(30000);
  #|       const result = await evaluate(`globalThis.$console.cmd(${JSON.stringify(request.command)}, ...${JSON.stringify(request.args || [])})`);
  #|       return { ok: true, result };
  #|     }
  #|     if (action === "eval") return { ok: true, result: await evaluate(String(request.expression || "")) };
  #|     if (action === "logs") {
  #|       const wanted = String(request.level || "");
  #|       const filtered = wanted === "" ? logs : logs.filter((entry) => entry.level === wanted);
  #|       return { ok: true, logs: filtered.slice(-200) };
  #|     }
  #|     if (action === "network") {
  #|       let entries = requestOrder.map((id) => requests.get(id)).filter(Boolean);
  #|       if (request.failed) entries = entries.filter((entry) => entry.failed || (entry.status || 0) >= 400);
  #|       return { ok: true, entries: entries.slice(-200) };
  #|     }
  #|     if (action === "screenshot") {
  #|       const result = await sendCdp("Page.captureScreenshot", { format: "png", captureBeyondViewport: false });
  #|       const out = String(request.out || "screenshot.png");
  #|       fs.writeFileSync(out, Buffer.from(result.data, "base64"));
  #|       return { ok: true, out };
  #|     }
  #|     if (action === "reload") {
  #|       await sendCdp("Page.reload", { ignoreCache: true });
  #|       return { ok: true, message: "reload requested" };
  #|     }
  #|     if (action === "verify-map") {
  #|       await waitForConsole(30000);
  #|       const mapId = String(request.command || "");
  #|       const portalId = String((request.args || [])[0] || "0");
  #|       const frames = Math.max(1, Number.parseInt(String(request.frames || "180"), 10) || 180);
  #|       const entry = await ensureGameActive();
  #|       const beforeErrors = logs.length;
  #|       const beforeRequests = requestOrder.length;
  #|       const commandResult = await evaluate(`globalThis.$console.cmd("temp_set_field_enter", ${JSON.stringify(mapId)}, ${JSON.stringify(portalId)})`);
  #|       await stepGame(frames);
  #|       const state = await readGameState();
  #|       const entries = requestOrder.slice(beforeRequests).map((id) => requests.get(id)).filter(Boolean);
  #|       const failures = entries.filter((entry) => entry.failed || (entry.status || 0) >= 400).slice(-80);
  #|       const recentErrors = logs.slice(beforeErrors).filter((entry) => entry.level === "error").slice(-80);
  #|       return { ok: true, mapId, portalId, frames, entry, commandResult, failures, recentErrors, state };
  #|     }
  #|     if (action === "close") {
  #|       setTimeout(() => shutdown("close requested"), 50);
  #|       return { ok: true, pid: process.pid, message: "close requested" };
  #|     }
  #|     return { ok: false, error: `unknown action: ${action}` };
  #|   };
  #|   const connectChrome = async () => {
  #|     const chromeCandidates = [
  #|       process.env.CHROME_BIN,
  #|       "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  #|       "/Applications/Chromium.app/Contents/MacOS/Chromium",
  #|     ].filter(Boolean);
  #|     const chromePath = chromeCandidates.find((candidate) => fs.existsSync(candidate));
  #|     if (!chromePath) throw new Error("Chrome executable not found; set CHROME_BIN");
  #|     const response = await fetch(gameUrl, { method: "HEAD" });
  #|     if (response.status >= 400) throw new Error(`Vite URL returned HTTP ${response.status}: ${gameUrl}`);
  #|     fs.mkdirSync(userDataDir, { recursive: true });
  #|     chrome = childProcess.spawn(chromePath, [
  #|       `--remote-debugging-port=${cdpPort}`,
  #|       `--user-data-dir=${userDataDir}`,
  #|       "--disable-background-timer-throttling",
  #|       "--disable-renderer-backgrounding",
  #|       "--enable-unsafe-webgpu",
  #|       String(gameUrl),
  #|     ], { stdio: "ignore" });
  #|     chrome.on("exit", (code, signal) => {
  #|       pushLog("warn", "mapled", `Chrome exited code=${code} signal=${signal}`);
  #|       if (!finished) shutdown("chrome exited");
  #|     });
  #|     let target = null;
  #|     for (let i = 0; i < 80; i += 1) {
  #|       try {
  #|         const targets = await fetch(`http://127.0.0.1:${cdpPort}/json/list`).then((it) => it.json());
  #|         target = targets.find((item) => item.type === "page" && item.webSocketDebuggerUrl);
  #|         if (target) break;
  #|       } catch (_) {}
  #|       await sleep(250);
  #|     }
  #|     if (!target) throw new Error(`No CDP page target found on port ${cdpPort}`);
  #|     ws = new WebSocket(target.webSocketDebuggerUrl);
  #|     await new Promise((resolve, reject) => {
  #|       ws.addEventListener("open", resolve, { once: true });
  #|       ws.addEventListener("error", (event) => reject(new Error(event.message || "WebSocket error")), { once: true });
  #|     });
  #|   };
  #|   const attachCdpEvents = () => {
  #|     ws.addEventListener("message", (event) => {
  #|       const text = typeof event.data === "string" ? event.data : Buffer.from(event.data).toString("utf8");
  #|       let msg;
  #|       try { msg = JSON.parse(text); } catch (error) {
  #|         pushLog("error", "cdp", `invalid CDP message: ${error.message}`);
  #|         return;
  #|       }
  #|       if (msg.id != null) {
  #|         const waiter = pending.get(msg.id);
  #|         if (!waiter) return;
  #|         pending.delete(msg.id);
  #|         if (msg.error) waiter.reject(new Error(`${waiter.method}: ${msg.error.message}`));
  #|         else waiter.resolve(msg.result || {});
  #|         return;
  #|       }
  #|       if (msg.method === "Runtime.consoleAPICalled") {
  #|         const params = msg.params || {};
  #|         const text = (params.args || []).map((arg) => Object.prototype.hasOwnProperty.call(arg, "value") ? JSON.stringify(arg.value) : (arg.description || arg.type || "")).join(" ");
  #|         pushLog(params.type || "log", "console", text);
  #|       } else if (msg.method === "Runtime.exceptionThrown") {
  #|         const detail = msg.params?.exceptionDetails || {};
  #|         pushLog("error", "exception", detail.exception?.description || detail.text || "uncaught exception", { url: detail.url, line: detail.lineNumber });
  #|       } else if (msg.method === "Log.entryAdded") {
  #|         const entry = msg.params?.entry || {};
  #|         pushLog(entry.level || "log", entry.source || "log", entry.text || "", { url: entry.url, line: entry.lineNumber });
  #|       } else if (msg.method === "Network.requestWillBeSent") {
  #|         const p = msg.params || {};
  #|         rememberRequest(p.requestId, { url: p.request?.url, method: p.request?.method, type: p.type, started_at: Date.now() });
  #|       } else if (msg.method === "Network.responseReceived") {
  #|         const p = msg.params || {};
  #|         rememberRequest(p.requestId, { url: p.response?.url, status: p.response?.status, mime: p.response?.mimeType, type: p.type });
  #|         if ((p.response?.status || 0) >= 400) pushLog("error", "network", `HTTP ${p.response.status}: ${p.response.url}`);
  #|       } else if (msg.method === "Network.loadingFinished") {
  #|         const p = msg.params || {};
  #|         const current = requests.get(p.requestId);
  #|         rememberRequest(p.requestId, { finished_at: Date.now(), size: p.encodedDataLength, duration_ms: current?.started_at ? Date.now() - current.started_at : null });
  #|       } else if (msg.method === "Network.loadingFailed") {
  #|         const p = msg.params || {};
  #|         rememberRequest(p.requestId, { failed: true, error: p.errorText, canceled: p.canceled, finished_at: Date.now() });
  #|         pushLog("error", "network", `request failed: ${p.errorText || "unknown"} ${requests.get(p.requestId)?.url || ""}`);
  #|       }
  #|     });
  #|     ws.addEventListener("close", () => {
  #|       pushLog("warn", "cdp", "CDP WebSocket closed");
  #|       if (!finished) shutdown("cdp closed");
  #|     });
  #|   };
  #|   try {
  #|     writeState("initializing");
  #|     await fetch(gameUrl, { method: "HEAD" }).catch((error) => {
  #|       throw new Error(`Vite dev server is not reachable at ${gameUrl}: ${error.message}`);
  #|     });
  #|     writeState("starting");
  #|     await connectChrome();
  #|     attachCdpEvents();
  #|     await sendCdp("Runtime.enable");
  #|     await sendCdp("Log.enable");
  #|     await sendCdp("Network.enable");
  #|     await sendCdp("Page.enable");
  #|     try { fs.rmSync(socketPath, { force: true }); } catch (_) {}
  #|     server = net.createServer((socket) => {
  #|       let buffer = "";
  #|       socket.setEncoding("utf8");
  #|       socket.on("data", async (chunk) => {
  #|         buffer += chunk;
  #|         const newline = buffer.indexOf("\n");
  #|         if (newline < 0) return;
  #|         const line = buffer.slice(0, newline);
  #|         buffer = buffer.slice(newline + 1);
  #|         try {
  #|           const response = await handle(JSON.parse(line));
  #|           socket.end(`${JSON.stringify(response)}\n`);
  #|         } catch (error) {
  #|           pushLog("error", "mapled", error.stack || error.message);
  #|           socket.end(`${JSON.stringify({ ok: false, error: error.message })}\n`);
  #|         }
  #|       });
  #|     });
  #|     await new Promise((resolve, reject) => {
  #|       server.once("error", reject);
  #|       server.listen(socketPath, resolve);
  #|     });
  #|     try { fs.chmodSync(socketPath, 0o600); } catch (_) {}
  #|     fs.writeFileSync(pidPath, String(process.pid));
  #|     writeState("ready");
  #|     process.on("SIGINT", () => shutdown("SIGINT"));
  #|     process.on("SIGTERM", () => shutdown("SIGTERM"));
  #|     pushLog("info", "mapled", `listening on ${socketPath}`);
  #|     return await stopped;
  #|   } catch (error) {
  #|     writeState("failed");
  #|     try { fs.rmSync(socketPath, { force: true }); } catch (_) {}
  #|     removeOwnPid();
  #|     throw error;
  #|   }
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
  let cmd = @argparse.Command(
    "mapled",
    about="Maple Moon CDP daemon",
    options=[
      @argparse.OptionArg("cdp-port", default_values=["9333"]),
      @argparse.OptionArg("url", default_values=["http://localhost:8080"]),
    ],
  )
  let parsed = cmd.parse(argv=program_args()) catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(2)
      return
    }
  }
  let cdp_port = match parsed.values.get("cdp-port") {
    Some(values) => values[0]
    None => "9333"
  }
  let game_url = match parsed.values.get("url") {
    Some(values) => values[0]
    None => "http://localhost:8080"
  }
  let result = run_mapled(cdp_port, game_url).wait() catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(1)
      return
    }
  }
  println(result)
}
