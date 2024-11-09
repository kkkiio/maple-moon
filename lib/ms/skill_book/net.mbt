pub fn handle_update_skill(
  player_getter : () -> @player.Player?,
  recv : @net.InPacket
) -> Unit! {
  recv.skip!(3)
  let skillid = recv.read_int!()
  let level = recv.read_int!()
  let masterlevel = recv.read_int!()
  let expire = recv.read_long!()
  match player_getter() {
    Some(player) =>
      player.change_skill(skillid, level, masterlevel, expire.to_int())
    None => ()
  }
  // TODO: update ui
}
