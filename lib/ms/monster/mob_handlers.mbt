pub fn handle_kill_mob(mobs : MapMobs, recv : @net.InPacket) -> Unit! {
  let oid = recv.read_int!()
  let animation = recv.read_byte!()
  mobs.remove(oid, animation)
}

pub fn handle_show_mob_hp(
  mobs : MapMobs,
  player_stats_getter : () -> @char_stats.CharStats?,
  recv : @net.InPacket
) -> Unit! {
  guard let Some(player_stats) = player_stats_getter() else { None => return  }
  let oid = recv.read_int!()
  let hppercent = recv.read_byte!()
  mobs.send_mobhp(oid, hppercent, player_stats.get_level())
}
