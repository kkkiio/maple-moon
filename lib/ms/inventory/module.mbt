///|
struct Module {
  inventory : Inventory
  player_getter : () -> @player.Player?
  resources : ItemInventoryUIResources
  io_service : @io_task.Service
}

///|
pub fn Module::load(
  player_getter : () -> @player.Player?,
  io_service : @io_task.Service
) -> @utils.Future[Module] {
  ItemInventoryUIResources::load()
  |> @utils.map(fn(resources) {
    { inventory: Inventory::new(), player_getter, resources, io_service }
  })
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
) -> Map[@keyboard.ActionId, @action.Descriptor] {
  [
    (
      @keyboard.ActionId::ITEMS,
      @action.Descriptor::UI(
        key=@ui.UIElementType::ITEM_INVENTORY,
        make_element=fn() {
          @ui.Element::new(
            fn(hooks) {
              let ui = ItemInventoryUI::new(
                self.inventory,
                self.io_service,
                self.resources,
                hooks,
                on_changing_equip=fn(slot, equip_data) {
                  guard let Some(player) = (self.player_getter)() else {
                    None => return
                  }
                  if can_wear_equip(player, equip_data) {
                    new_equip_item_packet(
                      slot,
                      self.inventory.find_equipslot(equip_data),
                    ).dispatch()
                  }
                },
                on_using_item=fn(slot, itemid) {
                  new_use_item_packet(slot, itemid).dispatch()
                },
              )
              ui
            },
            @ui.UIElementType::ITEM_INVENTORY,
          )
        },
        focused=ItemInventoryUI::is_focused(),
      ),
    ),
  ]
  |> Map::from_array
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
pub fn new_equip_item_packet(
  src : Int,
  dest : @equip_slot.Id
) -> @net.OutPacket {
  new_move_item_packet(TypeId::EQUIP, src, -dest.int_value(), 1)
}
