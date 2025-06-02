///|
struct Mod {
  mode : ModificationMode
  t : TypeId
  pos : Int
  arg : Int
} derive(ToJson, Show)

///|
priv struct ModifyInventoryMessage {
  mods : Array[Mod]
  mov : Movement?
} derive(ToJson, Show)

///| Parse MODIFY_INVENTORY message
fn parse_modify_inventory(recv : @net.InPacket) -> ModifyInventoryMessage! {
  recv.read_bool!() |> ignore // 'updatetick'
  let mods = Array::new()
  let size = recv.read_byte!()
  for i in 0..<size {
    let mode = recv.read_byte!()
    let t = TypeId::by_value(recv.read_byte!()) |> Option::unwrap
    let pos = recv.read_short!()
    let mut arg = 0
    let modification = match mode {
      0 => ModificationMode::ADD(parse_item!(recv, t, pos))
      1 => {
        arg = recv.read_short!()
        ModificationMode::CHANGE_COUNT
      }
      2 => {
        arg = recv.read_short!()
        ModificationMode::SWAP
      }
      3 => ModificationMode::REMOVE
      4 => ModificationMode::ADD_COUNT
      _ => fail!("Unknown modification mode: \{mode}")
    }
    mods.push({ mode: modification, t, pos, arg })
  }
  let mov = if recv.available() > 0 {
    Movement::from_int!(recv.read_byte!()) |> Some
  } else {
    None
  }
  { mods, mov }
}

///|
fn handle_modify_inventory(
  inventory : Inventory,
  player_getter : () -> @player.Player?,
  message : ModifyInventoryMessage
) -> Unit {
  guard player_getter() is Some(player) else { return }
  for mod in message.mods {
    match mod.mode {
      ModificationMode::ADD(item) => handle_item(inventory, item)
      ModificationMode::CHANGE_COUNT =>
        inventory.modify(mod.t, mod.pos, mod.mode, mod.arg, Movement::MOVE_NONE)
      ModificationMode::REMOVE =>
        inventory.modify(mod.t, mod.pos, mod.mode, 0, Movement::MOVE_INTERNAL)
      _ => ()
    }
  }
  let mov = message.mov.or(Movement::MOVE_INTERNAL)
  for mod in message.mods {
    match mod.mode {
      ModificationMode::SWAP =>
        inventory.modify(mod.t, mod.pos, mod.mode, mod.arg, mov)
      _ => ()
    }
    match mov {
      Movement::MOVE_INTERNAL =>
        match mod.t {
          TypeId::EQUIPPED => {
            change_equipment(inventory, player, -mod.pos)
            change_equipment(inventory, player, -mod.arg)
          }
          TypeId::EQUIP
          | TypeId::USE
          | TypeId::SETUP
          | TypeId::ETC
          | TypeId::CASH => ()
        }
      Movement::MOVE_EQUIP | Movement::MOVE_UNEQUIP =>
        if mod.pos < 0 {
          change_equipment(inventory, player, -mod.pos)
        } else if mod.arg < 0 {
          change_equipment(inventory, player, -mod.arg)
        }
      _ => ()
    }
  }
  player.recalc_stats(true)
}

///|
fn change_equipment(
  inventory : Inventory,
  player : @player.Player,
  raw_slot_id : Int
) -> Unit {
  let slot = @equip_slot.Id::from_int(raw_slot_id)
  match inventory.get_item_id(TypeId::EQUIPPED, raw_slot_id) {
    0 => player.character.get_look().remove_equip(slot)
    itemid => player.character.get_look().add_equip(itemid, slot)
  }
}

///| Packet which requests that an item is unequipped
struct UnequipItemPacket {
  src : Int
  dest : Int
} derive(ToJson, Show)

///|
pub impl @net.OutMessage for UnequipItemPacket with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.MOVE_ITEM)
  packet..write_short(self.src)..write_short(self.dest)
  packet
}

///|
priv struct UseItemMessage {
  slot_no : Int
  itemid : Int
} derive(Show)

///|
fn UseItemMessage::new(slot_no : Int, itemid : Int) -> UseItemMessage {
  { slot_no, itemid }
}

///|
impl @net.OutMessage for UseItemMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::USE_ITEM)
  packet..write_time()..write_short(self.slot_no)..write_int(self.itemid)
  packet
}

///| Packet which requests that an item is moved
pub fn new_move_item_packet(
  type_id : TypeId,
  slot : Int,
  action : Int,
  qty : Int
) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::MOVE_ITEM)
  packet
  ..write_time()
  ..write_byte(type_id.int_value().to_byte())
  ..write_short(slot)
  ..write_short(action)
  ..write_short(qty)
  packet
}
