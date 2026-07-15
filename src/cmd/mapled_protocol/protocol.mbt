///|
/// Normalize one Chrome DevTools Protocol event into the daemon's internal
/// event format. Unknown events become `{ "kind": "ignore" }`; malformed
/// messages become `{ "kind": "invalid", ... }` instead of raising.
///
/// # Example
/// ```moonbit nocheck
/// let event = summarize_cdp_event(
///   #|{"method":"Network.loadingFinished","params":{"requestId":"1","encodedDataLength":42}}
///   ,
///   1000.0,
/// )
/// guard event is { "kind": "network-finished", .. }
/// ```
pub fn summarize_cdp_event(message : String, time : Double) -> Json {
  let json = @json.parse(message) catch {
    err =>
      return { "kind": "invalid", "error": err.to_string(), "message": message }
  }
  match json {
    {
      "method": "Runtime.consoleAPICalled",
      "params": { "type": String(level), "args": Array(args), .. },
      ..
    } => {
      let parts : Array[String] = []
      for arg in args {
        let part = match arg {
          { "value": value, .. } => value.stringify()
          { "description": String(description), .. } => description
          { "type": String(type_), .. } => type_
          _ => ""
        }
        parts.push(part)
      }
      {
        "kind": "log",
        "time": time,
        "level": level,
        "source": "console",
        "text": parts.join(" "),
        "url": Json::null(),
        "line": Json::null(),
      }
    }
    { "method": "Runtime.exceptionThrown", "params": params, .. } => {
      let detail = match params {
        { "exceptionDetails": value, .. } => value
        _ => Json::empty_object()
      }
      let text = match detail {
        { "exception": { "description": String(value), .. }, .. } => value
        { "text": String(value), .. } => value
        _ => "uncaught exception"
      }
      let url : Json = match detail {
        { "url": String(value), .. } => Json::string(value)
        _ => Json::null()
      }
      let line : Json = match detail {
        { "lineNumber": Number(value, ..), .. } => Json::number(value)
        _ => Json::null()
      }
      {
        "kind": "log",
        "time": time,
        "level": "error",
        "source": "exception",
        "text": text,
        "url": url,
        "line": line,
      }
    }
    { "method": "Log.entryAdded", "params": { "entry": entry, .. }, .. } => {
      let level = match entry {
        { "level": String(value), .. } => value
        _ => "log"
      }
      let source = match entry {
        { "source": String(value), .. } => value
        _ => "log"
      }
      let text = match entry {
        { "text": String(value), .. } => value
        _ => ""
      }
      let url : Json = match entry {
        { "url": String(value), .. } => Json::string(value)
        _ => Json::null()
      }
      let line : Json = match entry {
        { "lineNumber": Number(value, ..), .. } => Json::number(value)
        _ => Json::null()
      }
      {
        "kind": "log",
        "time": time,
        "level": level,
        "source": source,
        "text": text,
        "url": url,
        "line": line,
      }
    }
    {
      "method": "Network.requestWillBeSent",
      "params": {
        "requestId": String(request_id),
        "request": { "url": String(url), "method": String(request_method), .. },
        "type": String(type_),
        ..
      },
      ..
    } =>
      {
        "kind": "network-request",
        "requestId": request_id,
        "url": url,
        "method": request_method,
        "type": type_,
        "time": time,
      }
    {
      "method": "Network.responseReceived",
      "params": {
        "requestId": String(request_id),
        "response": {
          "url": String(url),
          "status": Number(status, ..),
          "mimeType": String(mime),
          ..
        },
        "type": String(type_),
        ..
      },
      ..
    } =>
      {
        "kind": "network-response",
        "requestId": request_id,
        "url": url,
        "status": status,
        "mime": mime,
        "type": type_,
        "time": time,
      }
    {
      "method": "Network.loadingFinished",
      "params": {
        "requestId": String(request_id),
        "encodedDataLength": Number(size, ..),
        ..
      },
      ..
    } =>
      {
        "kind": "network-finished",
        "requestId": request_id,
        "size": size,
        "time": time,
      }
    {
      "method": "Network.loadingFailed",
      "params": {
        "requestId": String(request_id),
        "errorText": String(error),
        ..
      } as params,
      ..
    } => {
      let canceled : Json = match params {
        { "canceled": True, .. } => Json::boolean(true)
        { "canceled": False, .. } => Json::boolean(false)
        _ => Json::boolean(false)
      }
      {
        "kind": "network-failed",
        "requestId": request_id,
        "error": error,
        "canceled": canceled,
        "time": time,
      }
    }
    _ => { "kind": "ignore" }
  }
}

///|
/// Select the first page target whose URL starts with `game_url`, returning
/// its WebSocket debugger URL. Non-array input and incomplete targets return
/// `None`.
///
/// # Example
/// ```moonbit nocheck
/// let targets : Json = [{
///   "type": "page",
///   "url": "http://localhost:8080/game_debug.html",
///   "webSocketDebuggerUrl": "ws://127.0.0.1/devtools/page/1",
/// }]
/// inspect(select_cdp_target(targets, "http://localhost:8080"), content="Some(\"ws://127.0.0.1/devtools/page/1\")")
/// ```
pub fn select_cdp_target(targets : Json, game_url : String) -> String? {
  guard targets is Array(items) else { return None }
  for item in items {
    match item {
      {
        "type": "page",
        "url": String(url),
        "webSocketDebuggerUrl": String(websocket_url),
        ..
      } if url.has_prefix(game_url) => return Some(websocket_url)
      _ => ()
    }
  }
  None
}
