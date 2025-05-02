///|
struct Mod {
  mode : Modification
  t : TypeId
  pos : Int
  arg : Int
} derive(ToJson, Show)

///|
struct ModifyInventoryMessage {
  mods : Array[Mod]
  mov : Movement?
} derive(ToJson, Show)

///| Parse MODIFY_INVENTORY message
fn parse_modify_inventory(
  recv : @net.InPacket,
  inventory : Inventory
) -> ModifyInventoryMessage! {
  recv.read_bool!() |> ignore // 'updatetick'
  let mods = Array::new()
  let size = recv.read_byte!()
  for i in 0..<size {
    let mut mode = recv.read_byte!() |> Modification::from_int!()
    let t = TypeId::by_value(recv.read_byte!()) |> Option::unwrap
    let pos = recv.read_short!()
    let mut arg = 0
    match mode {
      Modification::ADD => {
        let item = parse_item!(recv, t, pos)
        handle_item(inventory, item)
      }
      Modification::CHANGE_COUNT => {
        arg = recv.read_short!()
        let count_before = inventory.get_item_count(t, pos)
        let count_now = arg
        inventory.modify(t, pos, mode, arg, Movement::MOVE_NONE)
        if count_before < count_now {
          mode = Modification::ADD_COUNT
        }
      }
      Modification::SWAP => arg = recv.read_short!()
      Modification::REMOVE =>
        inventory.modify(t, pos, mode, arg, Movement::MOVE_INTERNAL)
      _ => ()
    }
    mods.push({ mode, t, pos, arg })
  }
  let mov = if recv.available() {
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
  guard let Some(player) = player_getter() else { None => return }
  let mov = message.mov.or(Movement::MOVE_INTERNAL)
  for mod in message.mods {
    match mod.mode {
      Modification::SWAP =>
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
  @net.OutPacket::new(@net.MOVE_ITEM)
  ..write_short(self.src)
  ..write_short(self.dest)
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
  @net.OutPacket::new(@net.OutPacketOpcode::USE_ITEM)
  ..write_time()
  ..write_short(self.slot_no)
  ..write_int(self.itemid)
}

///| Packet which requests that an item is moved
pub fn new_move_item_packet(
  type_id : TypeId,
  slot : Int,
  action : Int,
  qty : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::MOVE_ITEM)
  ..write_time()
  ..write_byte(type_id.int_value().to_byte())
  ..write_short(slot)
  ..write_short(action)
  ..write_short(qty)
}
