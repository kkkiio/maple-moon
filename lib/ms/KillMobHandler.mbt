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
