///|
test "normalize console and network CDP events" {
  let console_message =
    #|{"method":"Runtime.consoleAPICalled","params":{"type":"warning","args":[{"value":"hello"},{"description":"Object"}]}}
  let exception_message =
    #|{"method":"Runtime.exceptionThrown","params":{"exceptionDetails":{"exception":{"description":"Error: boom"},"url":"http://localhost:8080/game.js","lineNumber":41}}}
  let request_message =
    #|{"method":"Network.requestWillBeSent","params":{"requestId":"request-1","request":{"url":"http://localhost:8080/assets/map.tmj","method":"GET"},"type":"Fetch"}}
  let response_message =
    #|{"method":"Network.responseReceived","params":{"requestId":"request-1","response":{"url":"http://localhost:8080/assets/map.tmj","status":404,"mimeType":"text/html"},"type":"Fetch"}}
  let finished_message =
    #|{"method":"Network.loadingFinished","params":{"requestId":"request-1","encodedDataLength":512}}
  let failed_message =
    #|{"method":"Network.loadingFailed","params":{"requestId":"request-2","errorText":"net::ERR_ABORTED","canceled":true}}
  json_inspect([
    @mapled_protocol.summarize_cdp_event(
      console_message,
      1000.0,
    ),
    @mapled_protocol.summarize_cdp_event(
      exception_message,
      1100.0,
    ),
    @mapled_protocol.summarize_cdp_event(
      request_message,
      1200.0,
    ),
    @mapled_protocol.summarize_cdp_event(
      response_message,
      1300.0,
    ),
    @mapled_protocol.summarize_cdp_event(
      finished_message,
      1400.0,
    ),
    @mapled_protocol.summarize_cdp_event(
      failed_message,
      1500.0,
    ),
  ], content=([{"kind":"log","time":1000,"level":"warning","source":"console","text":"\"hello\" Object","url":null,"line":null},{"kind":"log","time":1100,"level":"error","source":"exception","text":"Error: boom","url":"http://localhost:8080/game.js","line":41},{"kind":"network-request","requestId":"request-1","url":"http://localhost:8080/assets/map.tmj","method":"GET","type":"Fetch","time":1200},{"kind":"network-response","requestId":"request-1","url":"http://localhost:8080/assets/map.tmj","status":404,"mime":"text/html","type":"Fetch","time":1300},{"kind":"network-finished","requestId":"request-1","size":512,"time":1400},{"kind":"network-failed","requestId":"request-2","error":"net::ERR_ABORTED","canceled":true,"time":1500}]))
}

///|
test "select matching CDP page target" {
  let targets : Json = [
    {
      "type": "page",
      "url": "http://localhost:8080/other.html",
      "webSocketDebuggerUrl": "ws://127.0.0.1/devtools/page/other",
    },
    {
      "type": "page",
      "url": "http://localhost:8080/game_debug.html",
      "webSocketDebuggerUrl": "ws://127.0.0.1/devtools/page/game",
    },
  ]
  json_inspect(
    match @mapled_protocol.select_cdp_target(
      targets,
      "http://localhost:8080/game_debug",
    ) {
      Some(target) => ({ "target": target } : Json)
      None => Json::null()
    },
  content=({"target":"ws://127.0.0.1/devtools/page/game"}))
}
