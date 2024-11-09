struct Module {
  inventory : Inventory
  player_getter : () -> @player.Player?
}

pub fn Module::new(player_getter : () -> @player.Player?) -> Module {
  { inventory: Inventory::new(), player_getter }
}

pub fn get_inventory(self : Module) -> Inventory {
  self.inventory
}

pub fn make_handlers(
  self : Module
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
  [
    (
      @net.MODIFY_INVENTORY,
      @net.with_log(
        @net.MODIFY_INVENTORY,
        fn(recv : @net.InPacket) {
          handle_modify_inventory!(self.inventory, self.player_getter, recv)
        },
      ),
    ),
  ]
}

pub fn make_actions(self : Module) -> Array[(@action.Id, @action.Descriptor)] {
  [
    (
      @action.Id::ITEMS,
      @action.Descriptor::UI(
        key=@ui.UIElementType::ITEM_INVENTORY,
        make_element=fn() {
          let ui = UIItemInventory::new(
            {
              inventory: self.inventory,
              player: (self.player_getter)().unwrap(),
            },
          )
          self.inventory.listen_item_changes(
            fn() {
              guard ui.get_ui_model().active else { return false }
              ui.set_attributes(
                {
                  inventory: self.inventory,
                  player: (self.player_getter)().unwrap(),
                },
              )
              true
            },
          )
          @ui.Element::new(
            ui,
            @ui.UIElementType::ITEM_INVENTORY,
            doubleclick=fn(pos) { ui.doubleclick(pos) },
          )
        },
        focused=UIItemInventory::is_focused(),
      ),
    ),
  ]
}
