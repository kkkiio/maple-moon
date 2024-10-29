struct Module {
  inventory : Inventory
}

pub fn Module::new() -> Module {
  { inventory: Inventory::new() }
}

pub fn get_inventory(self : Module) -> Inventory {
  self.inventory
}

pub fn make_handlers(
  self : Module,
  player_getter : () -> @player.Player?
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
  [
    (
      @net.MODIFY_INVENTORY,
      @net.with_log(
        @net.MODIFY_INVENTORY,
        fn(recv : @net.InPacket) {
          handle_modify_inventory!(self.inventory, player_getter, recv)
        },
      ),
    ),
  ]
}
