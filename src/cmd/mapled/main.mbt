///|
async fn main {
  let cmd = @argparse.Command("mapled", about="Maple Moon CDP daemon", options=[
    @argparse.OptionArg("cdp-port", default_values=["9333"]),
    @argparse.OptionArg("url", default_values=["http://localhost:8080"]),
  ])
  let parsed = cmd.parse(argv=program_args()) catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(2)
      return
    }
  }
  let cdp_port_text = match parsed.values.get("cdp-port") {
    Some(values) => values[0]
    None => "9333"
  }
  let cdp_port = @string.parse_int(cdp_port_text) catch {
    _ => {
      write_stderr("invalid CDP port: \{cdp_port_text}\n")
      exit(2)
      return
    }
  }
  if cdp_port <= 0 {
    write_stderr("invalid CDP port: \{cdp_port_text}\n")
    exit(2)
    return
  }
  let game_url = match parsed.values.get("url") {
    Some(values) => values[0]
    None => "http://localhost:8080"
  }
  let result = Daemon::new(cdp_port, game_url).run() catch {
    err => {
      write_stderr(err.to_string() + "\n")
      exit(1)
      return
    }
  }
  println(result)
}
