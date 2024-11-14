pub fn parse_item(
  recv : @net.InPacket,
  invtype : TypeId,
  slot : Int,
  inventory : Inventory
) -> Unit! {
  // Read type and item id
  recv.read_byte!() |> ignore // 'type' byte
  let iid = recv.read_int!()
  if invtype == TypeId::EQUIP || invtype == TypeId::EQUIPPED {
    // Parse an equip
    parse_add_equip!(recv, invtype, slot, iid, inventory)
  } else if iid >= 5000000 && iid <= 5000102 {
    // Parse a pet
    parse_add_pet!(recv, invtype, slot, iid, inventory)
  } else {
    // Parse a normal item
    parse_add_item!(recv, invtype, slot, iid, inventory)
  }
}

// Parse an equip from a packet
fn parse_add_equip(
  recv : @net.InPacket,
  invtype : TypeId,
  slot : Int,
  id : Int,
  inventory : Inventory
) -> Unit! {
  // Read equip information
  let cash = recv.read_bool!()
  if cash {
    recv.skip!(8)
  } // unique id
  let expire = recv.read_long!()
  let slots = recv.read_ubyte!()
  let level = recv.read_ubyte!()

  // Read equip stats
  // EnumMap<EquipStat::Id, uint16_t> stats;
  let stats = Map::new()
  for id in @equip_stat.all_stats {
    stats[id] = recv.read_short!()
  }

  // Some more information
  let owner = recv.read_string!()
  let flag = recv.read_short!()
  let mut itemlevel = 0
  let mut itemexp = 0
  let mut vicious = 0
  if cash {
    // Some unused bytes
    recv.skip!(10)
  } else {
    recv.read_byte!() |> ignore
    itemlevel = recv.read_ubyte!()
    recv.read_short!() |> ignore
    itemexp = recv.read_ushort!()
    vicious = recv.read_int!()
    recv.read_long!() |> ignore
  }
  recv.skip!(12)
  let mut invtype = invtype
  let mut slot = slot
  if slot < 0 {
    invtype = TypeId::EQUIPPED
    slot = -slot
  }
  inventory.add_equip(
    invtype, slot, id, cash, expire, slots, level, stats, owner, flag, itemlevel,
    itemexp, vicious,
  )
}

// Parse a normal item from a packet
fn parse_add_item(
  recv : @net.InPacket,
  invtype : TypeId,
  slot : Int,
  id : Int,
  inventory : Inventory
) -> Unit! {
  // Read all item stats
  let cash = recv.read_bool!()
  if cash {
    recv.skip!(8)
  } // unique id
  let expire = recv.read_long!()
  let count = recv.read_short!()
  let owner = recv.read_string!()
  let flag = recv.read_short!()

  // If the item is a rechargeable projectile, some additional bytes are sent.
  if id / 10000 == 233 || id / 10000 == 207 {
    recv.skip!(8)
  }
  inventory.add_item(invtype, slot, id, cash, expire, count, owner, flag)
}

// Parse a pet from a packet
fn parse_add_pet(
  recv : @net.InPacket,
  invtype : TypeId,
  slot : Int,
  id : Int,
  inventory : Inventory
) -> Unit! {
  // Read all pet stats
  let cash = recv.read_bool!()
  if cash {
    recv.skip!(8)
  } // unique id
  recv.read_long!() |> ignore // expire
  let petname = recv.read_padded_string!(13)
  recv.read_byte!() |> ignore // petlevel
  recv.read_short!() |> ignore // closeness
  recv.read_byte!() |> ignore // fullness

  // Some unused bytes
  recv.skip!(18)
  inventory.add_pet(invtype, slot, id, cash, petname)
}
