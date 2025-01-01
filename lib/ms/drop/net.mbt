///|
pub struct DropLoot {
  mode : Int
  oid : Int
  meso : Bool
  item_id : Int
  owner : Int
  pickuptype : Int
  dropto : @struct.Point[Int]
  dropfrom : @struct.Point[Int]
  player_drop : Bool
} derive(Show)

///|
pub fn parse_drop_loot(recv : @net.InPacket) -> DropLoot! {
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
  { mode, oid, meso, item_id, owner, pickuptype, dropto, dropfrom, player_drop }
}

///|
pub fn handle_drop_loot_parsed(map_drops : MapDrops, drop : DropLoot) -> Unit {
  // TODO: sound
  map_drops.spawn({
    oid: drop.oid,
    item_id: drop.item_id,
    meso: drop.meso,
    owner: drop.owner,
    start: drop.dropfrom,
    dest: drop.dropto,
    drop_type: drop.pickuptype,
    mode: drop.mode,
    player_drop: drop.player_drop,
  })
}

///|
pub struct RemoveLoot {
  mode : Int
  oid : Int
  looter : @physics.PhysicsObject?
} derive(Show)

///|
pub fn parse_remove_loot(
  get_character_phys_by_id_fn : (Int) -> @physics.PhysicsObject?,
  recv : @net.InPacket
) -> RemoveLoot! {
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
  { mode, oid, looter }
}

///|
pub fn handle_remove_loot_parsed(
  map_drops : MapDrops,
  remove : RemoveLoot
) -> Unit {
  map_drops.remove(remove.oid, remove.mode, remove.looter)
}
