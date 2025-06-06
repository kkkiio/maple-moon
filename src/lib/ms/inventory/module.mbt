///|
struct Module {
  inventory : Inventory
  player_getter : () -> @player.Player?
  network : @net.Network
  string_loader : @resource.SyncLoader
}

///|
pub fn Module::load(
  player_getter : () -> @player.Player?,
  network : @net.Network,
  string_loader : @resource.SyncLoader
) -> Module {
  { inventory: Inventory::new(network), player_getter, network, string_loader }
}

///|
pub fn get_inventory(self : Module) -> Inventory {
  self.inventory
}

///|
pub fn make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(
      @net.MODIFY_INVENTORY,
      parse_modify_inventory,
      fn(message) {
        handle_modify_inventory(self.inventory, self.player_getter, message)
      },
      log_recv=true,
    ),
  ]
  |> Map::from_array
}

///|
pub fn make_actions(
  self : Module
) -> Map[@keyboard.BasicActionId, @action.Descriptor] {
  Map::new()
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
  [
    (
      @maple_stat.Id::MESO,
      fn(meso) {
        self.inventory.set_meso(meso)
        false
      },
    ),
  ]
  |> Map::from_array
}

///|
pub fn make_show_status_info_handlers(
  self : Module
) -> Map[Int, @game_mod.SubRouteHandler] {
  {
    0: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction! {
      let second_byte = recv.read_byte!()
      match second_byte {
        1 => { // meso gain
          // Structure: writeByte(0) + writeShort(1) + writeInt(gain) + writeShort(0)
          recv.skip(1) // skip the second byte of the short
          let gain = recv.read_int!()
          let _unused = recv.read_short!() // Always 0
          { message: ShowGainMessage::MesoGain(gain~) }
        }
        0 => { // item gain
          // Structure: writeShort(0) + writeInt(itemId) + writeInt(quantity) + writeInt(0) + writeInt(0)
          let item_id = recv.read_int!()
          let quantity = recv.read_int!()
          let _unused1 = recv.read_int!() // Always 0
          let _unused2 = recv.read_int!() // Always 0
          { message: ShowGainMessage::ItemGain(item_id~, quantity~) }
        }
        mode => { // inventory status
          // Structure: writeByte(0) + writeByte(mode) + writeInt(0) + writeInt(0)
          let _unused1 = recv.read_int!() // Always 0
          let _unused2 = recv.read_int!() // Always 0
          { message: ShowGainMessage::InventoryStatus(mode~) }
        }
      }
    },
  }
}

///| Packet which requests that an item is equipped
priv struct EquipItemMessage {
  src : Int
  dest : @equip_slot.Id
} derive(Show)

///|
impl @net.OutMessage for EquipItemMessage with pack(self) -> @net.OutPacket {
  new_move_item_packet(TypeId::EQUIP, self.src, -self.dest.int_value(), 1)
}

///|
priv enum ShowGainMessage {
  MesoGain(gain~ : Int)
  ItemGain(item_id~ : Int, quantity~ : Int)
  InventoryStatus(mode~ : Int)
} derive(Show)

///|
struct ShowGainAction {
  message : ShowGainMessage
}

///|
impl Show for ShowGainAction with output(self, logger) {
  self.message.output(logger)
}

///|
impl @game_mod.SubRouteAction for ShowGainAction with handle(self) {
  @log.info({ "message": self.message }, "ShowGainAction")
  // TODO: Handle the message
}
