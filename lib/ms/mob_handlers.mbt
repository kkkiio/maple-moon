struct KillMobHandler {
  mobs : @monster.MapMobs
}

pub fn KillMobHandler::new(mobs : @monster.MapMobs) -> KillMobHandler {
  { mobs, }
}

pub fn KillMobHandler::handle(
  self : KillMobHandler,
  recv : @net.InPacket
) -> Unit! {
  let oid = recv.read_int!()
  let animation = recv.read_byte!()
  self.mobs.remove(oid, animation)
}

struct ShowMobHpHandler {
  mobs : @monster.MapMobs
}

pub fn ShowMobHpHandler::new(mobs : @monster.MapMobs) -> ShowMobHpHandler {
  { mobs, }
}

pub fn ShowMobHpHandler::handle(
  self : ShowMobHpHandler,
  recv : @net.InPacket
) -> Unit! {
  let oid = recv.read_int!()
  let hppercent = recv.read_byte!()
  let playerlevel = Stage::get().get_player().unwrap().get_stats().level
  self.mobs.send_mobhp(oid, hppercent, playerlevel)
}
