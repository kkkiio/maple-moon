///|
async fn main {
  let cmd = @argparse.Command("mapled", about="Maple Moon CDP daemon", options=[
    @argparse.OptionArg("cdp-port", default_values=["9333"]),
    @argparse.OptionArg("url", default_values=[
      "http://localhost:8080/game_debug.html",
    ]),
  ])
  let args = @env.args()[1:]
  if args.is_empty() {
    println(cmd.render_help())
    return
  }
  let parsed = cmd.parse(argv=args) catch {
    err => {
      @stdio.stderr.write(err.to_string() + "\n")
      @sys.exit(2)
      return
    }
  }
  let cdp_port_text = match parsed.values.get("cdp-port") {
    Some(values) | (None with values = ["9333"]) => values[0]
  }
  let cdp_port = @string.parse_int(cdp_port_text) catch {
    _ => {
      @stdio.stderr.write("invalid CDP port: \{cdp_port_text}\n")
      @sys.exit(2)
      return
    }
  }
  if cdp_port <= 0 {
    @stdio.stderr.write("invalid CDP port: \{cdp_port_text}\n")
    @sys.exit(2)
    return
  }
  let game_url = match parsed.values.get("url") {
    Some(values)
    | (None with values = ["http://localhost:8080/game_debug.html"]) =>
      values[0]
  }
  let result = Daemon(cdp_port, game_url).run() catch {
    error if @async.is_cancellation_error(error) => return
    err => {
      @stdio.stderr.write(err.to_string() + "\n")
      @sys.exit(1)
      return
    }
  }
  println(result)
}
