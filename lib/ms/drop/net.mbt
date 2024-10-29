pub fn handle_drop_loot(map_drops : MapDrops, recv : @net.InPacket) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  let meso = recv.read_bool!()
  let item_id = recv.read_int!()
  let owner = recv.read_int!()
  let pickuptype = recv.read_byte!()
  let dropto = recv.read_point!()
  recv.skip!(4)
  let dropfrom = if mode != 2 {
    let dropfrom = recv.read_point!()
    recv.skip!(2)
    dropfrom
  } else {
    dropto
  }
  if meso.not() {
    recv.skip!(8)
  }
  let player_drop = recv.read_bool!().not()

  // TODO: sound

  map_drops.spawn(
    {
      oid,
      item_id,
      meso,
      owner,
      start: dropfrom,
      dest: dropto,
      drop_type: pickuptype,
      mode,
      player_drop,
    },
  )
}

pub fn handle_remove_loot(
  map_drops : MapDrops,
  get_character_phys_by_id_fn : (Int) -> @physics.PhysicsObject?,
  recv : @net.InPacket
) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  let looter = if mode > 1 {
    let cid = recv.read_int!()
    if recv.available() {
      recv.read_byte!() |> ignore // pet
      None
    } else {
      get_character_phys_by_id_fn(cid)
    }
    // TODO: sound
  } else {
    None
  }
  map_drops.remove(oid, mode, looter)
}
