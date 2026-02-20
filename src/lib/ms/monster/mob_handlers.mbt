///|
pub fn handle_kill_mob(mobs : MapMobs, recv : @net.InPacket) -> Unit raise {
  let oid = recv.read_int()
  let animation = recv.read_byte()
  mobs.remove(oid, animation)
}
