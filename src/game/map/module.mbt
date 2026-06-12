///|
struct Module {
  portals_animations : MapPortalAnimations
}

///|
fn parse_int_arg(args : Array[String], index : Int, default : Int) -> Int {
  guard index >= 0 && index < args.length() else { return default }
  @string.parse_int(args[index]) catch {
    _ => default
  }
}

///|
fn init {
  @console.register_command("warp", fn(args) {
    let map_id = parse_int_arg(args, 0, 0)
    let portal_id = parse_int_arg(args, 1, 0)
    @game_server.send(
      @server_proto.AdminCommandMessage::Warp(map_id~, portal_id~),
    )
    { "ok": true, "code": "OK", "message": "warp command sent", "args": args }
  })
}

///|
pub fn Module::load() -> Module {
  let portals_animations = MapPortalAnimations::load()
  { portals_animations, }
}

///|
pub fn Module::get_portals_animations(self : Module) -> MapPortalAnimations {
  self.portals_animations
}
