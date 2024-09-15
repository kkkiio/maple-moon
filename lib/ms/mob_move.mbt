struct MobMovedHandler {
  map_mobs : @monster.MapMobs
  mob_combat : @monster_combat.MobCombat
}

pub fn MobMovedHandler::new(
  map_mobs : @monster.MapMobs,
  mob_combat : @monster_combat.MobCombat
) -> MobMovedHandler {
  { map_mobs, mob_combat }
}

pub fn MobMovedHandler::handle(
  self : MobMovedHandler,
  recv : @net.InPacket
) -> Unit! {
  let oid = recv.read_int!()
  recv.read_byte!() |> ignore // ?
  let use_skills = recv.read_bool!() // useskill
  let action = recv.read_byte!() // action
  let skillid = recv.read_ubyte!() // skill id
  let skill_level = recv.read_ubyte!() // skill level
  let option = recv.read_short!() // option
  let position = recv.read_point!()
  let movements = @physics.parse_movements!(recv)
  self.map_mobs.send_movement(oid, position, movements)
  self.mob_combat.use_move!(oid, action, skillid, skill_level)
}
