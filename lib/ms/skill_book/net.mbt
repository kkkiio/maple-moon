///|
pub struct SkillUpdate {
  skillid : Int
  level : Int
  masterlevel : Int
  expire : Int
} derive(Show)

///|
pub fn parse_skill_update(recv : @net.InPacket) -> SkillUpdate! {
  recv.skip!(3)
  let skillid = recv.read_int!()
  let level = recv.read_int!()
  let masterlevel = recv.read_int!()
  let expire = recv.read_long!()
  { skillid, level, masterlevel, expire: expire.to_int() }
}

///|
pub fn handle_skill_update(
  player_getter : () -> @player.Player?,
  update : SkillUpdate
) -> Unit {
  match player_getter() {
    Some(player) =>
      player.change_skill(
        update.skillid,
        update.level,
        update.masterlevel,
        update.expire,
      )
    None => ()
  }
  // TODO: update ui
}
