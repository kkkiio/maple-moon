///|
struct Module {
  inventory : Inventory
  player_getter : () -> @player.Player?
  item_res : @resource.NxNode
}

///|
pub fn Module::load(
  player_getter : () -> @player.Player?
) -> @utils.Future[Module] {
  @ui.ui_window_2_loader().load_res(["Item"])
  |> @utils.map(fn(item_res) { Module::new(player_getter, item_res) })
}

///|
fn Module::new(
  player_getter : () -> @player.Player?,
  item_res : @resource.NxNode
) -> Module {
  { inventory: Inventory::new(), player_getter, item_res }
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
    (
      @net.MODIFY_INVENTORY,
      @net.with_log(@net.MODIFY_INVENTORY, fn(recv : @net.InPacket) {
        handle_modify_inventory!(self.inventory, self.player_getter, recv)
      }),
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
              let ui = UIItemInventory::new(
                {
                  inventory: self.inventory,
                  player: (self.player_getter)().unwrap(),
                },
                self.item_res,
                hooks,
              )
              self.inventory.listen_item_changes(fn() {
                guard ui.get_ui_model().active else { return false }
                ui.set_attributes({
                  inventory: self.inventory,
                  player: (self.player_getter)().unwrap(),
                })
                true
              })
              ui
            },
            @ui.UIElementType::ITEM_INVENTORY,
          )
        },
        focused=UIItemInventory::is_focused(),
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
      {
        parse_fn: fn(recv) { recv.read_int!() },
        update_fn: fn(meso) {
          self.inventory.set_meso(meso)
          false
        },
      },
    ),
  ]
  |> Map::from_array
}
