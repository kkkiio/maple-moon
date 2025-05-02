///|
struct Module {
  inventory : Inventory
  player_getter : () -> @player.Player?
  network : @net.Network
}

///|
pub fn Module::load(
  player_getter : () -> @player.Player?,
  network : @net.Network
) -> @utils.Future[Module] {
  { inventory: Inventory::new(network), player_getter, network }
  |> @utils.Future::from_value
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
      fn(recv) { parse_modify_inventory!(recv, self.inventory) },
      fn(message) {
        handle_modify_inventory(self.inventory, self.player_getter, message)
      },
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

///| Packet which requests that an item is equipped
priv struct EquipItemMessage {
  src : Int
  dest : @equip_slot.Id
} derive(Show)

///|
impl @net.OutMessage for EquipItemMessage with pack(self) -> @net.OutPacket {
  new_move_item_packet(TypeId::EQUIP, self.src, -self.dest.int_value(), 1)
}
