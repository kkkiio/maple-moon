struct DropLootHandler {
  map_drops : MapDrops
}

pub fn DropLootHandler::new(map_drops : MapDrops) -> DropLootHandler {
  { map_drops, }
}

fn handle(self : DropLootHandler, recv : @net.InPacket) -> Unit! {
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

  self.map_drops.spawn(
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

struct RemoveLootHandler {
  map_drops : MapDrops
  get_character_by_id_fn : (Int) -> @character.Character?
}

pub fn RemoveLootHandler::new(
  map_drops : MapDrops,
  get_character_by_id_fn : (Int) -> @character.Character?
) -> RemoveLootHandler {
  { map_drops, get_character_by_id_fn }
}

fn handle(self : RemoveLootHandler, recv : @net.InPacket) -> Unit! {
  let mode = recv.read_byte!()
  let oid = recv.read_int!()
  let looter = if mode > 1 {
    let cid = recv.read_int!()
    if recv.available() {
      recv.read_byte!() |> ignore // pet
      None
    } else {
      match (self.get_character_by_id_fn)(cid) {
        Some(character) => Some(character.get_phobj())
        None => None
      }
    }
    // TODO: sound
  } else {
    None
  }
  self.map_drops.remove(oid, mode, looter)
}
