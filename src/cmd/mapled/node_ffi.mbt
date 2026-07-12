///|
#external
type JsCdp

///|
#external
type JsChrome

///|
#external
type JsServer

///|
#external
type JsSocket

///|
#external
type JsStopSignal

///|
#external
type JsObservedPromise

///|
extern "js" fn temp_path(name : String) -> String =
  #| (name) => require("node:path").join(require("node:os").tmpdir(), name)

///|
extern "js" fn process_pid() -> Int = "() => process.pid"

///|
extern "js" fn now_ms() -> Double = "() => Date.now()"

///|
extern "js" fn write_state_file(path : String, content : String) -> Unit =
  #| (path, content) => {
  #|   const fs = require("node:fs");
  #|   const tmp = `${path}.tmp`;
  #|   try {
  #|     fs.writeFileSync(tmp, content);
  #|     fs.renameSync(tmp, path);
  #|   } catch (_) {}
  #| }

///|
extern "js" fn remove_path(path : String) -> Unit =
  #| (path) => { try { require("node:fs").rmSync(path, { force: true }); } catch (_) {} }

///|
extern "js" fn write_text_file(path : String, content : String) -> Unit =
  #| (path, content) => require("node:fs").writeFileSync(path, content)

///|
extern "js" fn chmod_owner_only(path : String) -> Unit =
  #| (path) => { try { require("node:fs").chmodSync(path, 0o600); } catch (_) {} }

///|
extern "js" fn remove_own_pid(path : String, pid : Int) -> Unit =
  #| (path, pid) => {
  #|   const fs = require("node:fs");
  #|   try {
  #|     if (fs.readFileSync(path, "utf8").trim() === String(pid)) {
  #|       fs.rmSync(path, { force: true });
  #|     }
  #|   } catch (_) {}
  #| }

///|
extern "js" fn write_base64_file(path : String, content : String) -> Unit =
  #| (path, content) => require("node:fs").writeFileSync(path, Buffer.from(content, "base64"))

///|
extern "js" fn find_chrome() -> String =
  #| () => {
  #|   const fs = require("node:fs");
  #|   return [
  #|     process.env.CHROME_BIN,
  #|     "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  #|     "/Applications/Chromium.app/Contents/MacOS/Chromium",
  #|   ].filter(Boolean).find((path) => fs.existsSync(path)) || "";
  #| }

///|
extern "js" fn spawn_chrome(
  chrome_path : String,
  cdp_port : Int,
  user_data_dir : String,
  game_url : String,
  on_exit : (JsChrome, Int, String) -> Unit,
) -> JsChrome =
  #| (chromePath, cdpPort, userDataDir, gameUrl, onExit) => {
  #|   require("node:fs").mkdirSync(userDataDir, { recursive: true });
  #|   const child = require("node:child_process").spawn(chromePath, [
  #|     `--remote-debugging-port=${cdpPort}`,
  #|     `--user-data-dir=${userDataDir}`,
  #|     "--disable-background-timer-throttling",
  #|     "--disable-renderer-backgrounding",
  #|     "--enable-unsafe-webgpu",
  #|     gameUrl,
  #|   ], { stdio: "ignore" });
  #|   child.on("exit", (code, signal) => onExit(child, code == null ? -1 : code, String(signal || "")));
  #|   return child;
  #| }

///|
extern "js" fn same_chrome(left : JsChrome, right : JsChrome) -> Bool =
  "(left, right) => left === right"

///|
extern "js" fn kill_chrome(chrome : JsChrome) -> Unit =
  #| (chrome) => { try { chrome.kill("SIGKILL"); } catch (_) {} }

///|
extern "js" fn fetch_http(url : String, http_method : String) -> @js_async.Promise[String] =
  #| (url, method) => fetch(url, { method }).then(async (response) => JSON.stringify({
  #|   status: response.status,
  #|   body: method === "HEAD" ? "" : await response.text(),
  #| }))

///|
extern "js" fn encode_uri_component(value : String) -> String =
  "(value) => encodeURIComponent(value)"

///|
extern "js" fn open_cdp(
  url : String,
  on_event : (String) -> Unit,
  on_close : (JsCdp) -> Unit,
) -> @js_async.Promise[JsCdp] =
  #| (url, onEvent, onClose) => new Promise((resolve, reject) => {
  #|   if (typeof WebSocket !== "function") {
  #|     reject(new Error("Node native WebSocket is required"));
  #|     return;
  #|   }
  #|   const ws = new WebSocket(url);
  #|   const cdp = { ws, nextId: 1, pending: new Map() };
  #|   ws.addEventListener("open", () => resolve(cdp), { once: true });
  #|   ws.addEventListener("error", (event) => reject(new Error(event.message || "WebSocket error")), { once: true });
  #|   ws.addEventListener("message", (event) => {
  #|     const text = typeof event.data === "string" ? event.data : Buffer.from(event.data).toString("utf8");
  #|     let message;
  #|     try { message = JSON.parse(text); } catch (_) { onEvent(text); return; }
  #|     if (message.id == null) { onEvent(text); return; }
  #|     const pending = cdp.pending.get(message.id);
  #|     if (!pending) return;
  #|     cdp.pending.delete(message.id);
  #|     if (message.error) pending.reject(new Error(`${pending.method}: ${message.error.message}`));
  #|     else pending.resolve(JSON.stringify(message.result || {}));
  #|   });
  #|   ws.addEventListener("close", () => {
  #|     for (const pending of cdp.pending.values()) pending.reject(new Error("CDP WebSocket closed"));
  #|     cdp.pending.clear();
  #|     onClose(cdp);
  #|   });
  #| })

///|
extern "js" fn cdp_is_open(cdp : JsCdp) -> Bool =
  "(cdp) => cdp.ws.readyState === WebSocket.OPEN"

///|
extern "js" fn same_cdp(left : JsCdp, right : JsCdp) -> Bool =
  "(left, right) => left === right"

///|
extern "js" fn cdp_send(
  cdp : JsCdp,
  command_method : String,
  params : String,
) -> @js_async.Promise[String] =
  #| (cdp, method, paramsText) => new Promise((resolve, reject) => {
  #|   if (cdp.ws.readyState !== WebSocket.OPEN) {
  #|     reject(new Error("CDP WebSocket is not connected"));
  #|     return;
  #|   }
  #|   const id = cdp.nextId++;
  #|   cdp.pending.set(id, { resolve, reject, method });
  #|   cdp.ws.send(JSON.stringify({ id, method, params: JSON.parse(paramsText) }));
  #| })

///|
extern "js" fn close_cdp(cdp : JsCdp) -> Unit =
  #| (cdp) => { try { cdp.ws.close(); } catch (_) {} }

///|
extern "js" fn start_server(
  path : String,
  on_request : (JsSocket, String) -> @js_async.Promise[String],
  on_error : (String) -> Unit,
) -> @js_async.Promise[JsServer] =
  #| (path, onRequest, onError) => new Promise((resolve, reject) => {
  #|   const net = require("node:net");
  #|   const holder = { server: null, subscribers: new Set(), listening: false };
  #|   const server = net.createServer((socket) => {
  #|     let buffer = "";
  #|     socket.setEncoding("utf8");
  #|     socket.on("data", (chunk) => {
  #|       buffer += chunk;
  #|       const newline = buffer.indexOf("\n");
  #|       if (newline < 0) return;
  #|       const line = buffer.slice(0, newline);
  #|       buffer = buffer.slice(newline + 1);
  #|       Promise.resolve(onRequest(socket, line)).then(
  #|         (response) => { if (response !== "") socket.end(`${response}\n`); },
  #|         (error) => socket.end(`${JSON.stringify({ ok: false, error: String(error) })}\n`),
  #|       );
  #|     });
  #|   });
  #|   holder.server = server;
  #|   server.on("error", (error) => {
  #|     if (holder.listening) onError(error.stack || error.message);
  #|     else reject(error);
  #|   });
  #|   server.listen(path, () => { holder.listening = true; resolve(holder); });
  #| })

///|
extern "js" fn server_subscribe(server : JsServer, socket : JsSocket) -> Unit =
  #| (server, socket) => {
  #|   server.subscribers.add(socket);
  #|   const remove = () => server.subscribers.delete(socket);
  #|   socket.on("close", remove);
  #|   socket.on("error", remove);
  #| }

///|
extern "js" fn socket_write(socket : JsSocket, line : String) -> Unit =
  "(socket, line) => socket.write(line)"

///|
extern "js" fn server_broadcast(server : JsServer, line : String) -> Unit =
  #| (server, line) => {
  #|   for (const socket of server.subscribers) {
  #|     try { socket.write(line); } catch (_) { server.subscribers.delete(socket); }
  #|   }
  #| }

///|
extern "js" fn close_server(server : JsServer) -> Unit =
  #| (server) => {
  #|   try { server.server.close(); } catch (_) {}
  #|   for (const socket of server.subscribers) { try { socket.end(); } catch (_) {} }
  #|   server.subscribers.clear();
  #| }

///|
extern "js" fn new_stop_signal() -> JsStopSignal =
  #| () => {
  #|   const stop = { settled: false, resolve: null, promise: null };
  #|   stop.promise = new Promise((resolve) => { stop.resolve = resolve; });
  #|   return stop;
  #| }

///|
extern "js" fn wait_stop(signal : JsStopSignal) -> @js_async.Promise[String] =
  "(signal) => signal.promise"

///|
extern "js" fn resolve_stop(signal : JsStopSignal, message : String) -> Unit =
  #| (signal, message) => {
  #|   if (signal.settled) return;
  #|   signal.settled = true;
  #|   signal.resolve(message);
  #| }

///|
extern "js" fn observe_promise(
  promise : @js_async.Promise[String],
) -> JsObservedPromise =
  #| (promise) => {
  #|   const observed = { settled: false, ok: false, value: "", error: "" };
  #|   promise.then(
  #|     (value) => { observed.settled = true; observed.ok = true; observed.value = value; },
  #|     (error) => { observed.settled = true; observed.error = String(error); },
  #|   );
  #|   return observed;
  #| }

///|
extern "js" fn observed_settled(observed : JsObservedPromise) -> Bool =
  "(observed) => observed.settled"

///|
extern "js" fn observed_ok(observed : JsObservedPromise) -> Bool =
  "(observed) => observed.ok"

///|
extern "js" fn observed_value(observed : JsObservedPromise) -> String =
  "(observed) => observed.value"

///|
extern "js" fn observed_error(observed : JsObservedPromise) -> String =
  "(observed) => observed.error"

///|
extern "js" fn install_signals(on_signal : (String) -> Unit) -> Unit =
  #| (onSignal) => {
  #|   process.on("SIGINT", () => onSignal("SIGINT"));
  #|   process.on("SIGTERM", () => onSignal("SIGTERM"));
  #| }

///|
extern "js" fn schedule(delay_ms : Int, callback : () -> Unit) -> Unit =
  "(delayMs, callback) => setTimeout(callback, delayMs)"

///|
extern "js" fn program_args() -> Array[String] =
  "() => process.argv.slice(2)"

///|
extern "js" fn write_stderr(message : String) -> Unit =
  "(message) => process.stderr.write(message)"

///|
extern "js" fn exit(code : Int) -> Unit = "(code) => process.exit(code)"
