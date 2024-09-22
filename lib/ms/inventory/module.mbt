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
) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [
    (
      @net.MODIFY_INVENTORY,
      ModifyInventoryHandler::new(self.inventory, player_getter),
    ),
  ]
}
