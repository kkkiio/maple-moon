pub fn handle_mob_moved(
  map_mobs : MapMobs,
  mob_combat : MobCombat,
  recv : @net.InPacket
) -> Unit! {
  let oid = recv.read_int!()
  recv.read_byte!() |> ignore // ?
  recv.read_bool!() |> ignore // useskill
  let action = recv.read_byte!() // action
  let skillid = recv.read_ubyte!() // skill id
  let skill_level = recv.read_ubyte!() // skill level
  recv.read_short!() |> ignore // option
  let position = recv.read_point!()
  let movements = @physics.parse_movements!(recv)
  map_mobs.send_movement(oid, position, movements)
  mob_combat.use_move!(oid, action, skillid, skill_level)
}

pub fn handle_mob_move_response(
  mob_combat : MobCombat,
  recv : @net.InPacket
) -> Unit! {
  let oid = recv.read_int!()
  let moveid = recv.read_short!()
  recv.read_bool!() |> ignore // use_skills
  recv.read_ushort!() |> ignore // curr_mp
  let skillid = recv.read_ubyte!()
  let skill_level = recv.read_ubyte!()
  if skillid == 0 {
    // Stage::get().get_mob_combat().use_some_attack(oid);

  } else {
    mob_combat.use_move!(oid, moveid, skillid, skill_level)
  }
}
