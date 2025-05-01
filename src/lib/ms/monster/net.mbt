pub fn handle_spawn_mob(map_mobs : MapMobs, recv : @net.InPacket) -> Unit! {
  let oid = recv.read_int!()
  recv.read_byte!() |> ignore // 5 if controller == null
  let id = recv.read_int!()
  recv.skip!(16)
  let position = recv.read_point!()
  let stance = recv.read_byte!()
  recv.skip!(2) // origin fh
  let fh = recv.read_ushort!()
  let effect = recv.read_byte!()
  if effect > 0 {
    recv.read_byte!() |> ignore
    recv.read_short!() |> ignore
    if effect == 15 {
      recv.read_byte!() |> ignore
    }
  }
  let team = recv.read_byte!()
  recv.skip!(4) // item effect
  map_mobs.spawn(
    { oid, id, mode: 0, stance, fh, new_spawn: effect == -2, team, position },
  )
}

pub fn handle_spawn_mob_controller(
  map_mobs : MapMobs,
  recv : @net.InPacket
) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  if mode == 0 {
    map_mobs.set_control(oid, false)
  } else if recv.available() {
    recv.skip!(1)
    let id = recv.read_int!()
    recv.skip!(16)
    let position = recv.read_point!()
    let stance = recv.read_byte!()
    recv.skip!(2) // origin fh
    let fh = recv.read_ushort!()
    let effect = recv.read_byte!()
    if effect > 0 {
      recv.read_byte!() |> ignore
      recv.read_short!() |> ignore
      if effect == 15 {
        recv.read_byte!() |> ignore
      }
    }
    let team = recv.read_byte!()
    recv.skip!(4)
    map_mobs.spawn(
      { oid, id, mode, stance, fh, new_spawn: effect == -2, team, position },
    )
  } else {
    // TODO: Remove monster invisibility, not used (maybe in an event script?), Check this!
  }
}

/// Updates a mob's position with the server
fn new_move_mob_packet(
  oid : Int,
  t : Int,
  nibbles : Int,
  action : Int,
  skill : Int,
  skill_level : Int,
  option : Int,
  startpos : @struct.Point[Int],
  movement : @physics.Movement
) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::MOVE_MONSTER)
  packet.write_int(oid)
  packet.write_short(t) // moveid?
  packet.write_byte(nibbles.to_byte())
  packet.write_byte(action.to_byte())
  packet.write_byte(skill.to_byte())
  packet.write_byte(skill_level.to_byte())
  packet.write_short(option)
  packet.skip(13)
  packet.write_point(startpos)
  packet.write_byte((1).to_byte())
  @physics.write_movement(packet, movement)
  packet
}
