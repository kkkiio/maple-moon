struct UpdateSkillHandler {
  player_getter : () -> @player.Player?
}

pub fn UpdateSkillHandler::new(
  player_getter : () -> @player.Player?
) -> UpdateSkillHandler {
  { player_getter, }
}

impl @net.PacketHandler for UpdateSkillHandler with handle(
  self : UpdateSkillHandler,
  recv : @net.InPacket
) -> Unit! {
  recv.skip!(3)
  let skillid = recv.read_int!()
  let level = recv.read_int!()
  let masterlevel = recv.read_int!()
  let expire = recv.read_long!()
  match (self.player_getter)() {
    Some(player) =>
      player.change_skill(skillid, level, masterlevel, expire.to_int())
    None => ()
  }
  // TODO: update ui
}
