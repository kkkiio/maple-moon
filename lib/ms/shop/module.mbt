struct Module {
  countset : @graphics.Charset
  container : @ui.Container
}

pub fn Module::new(container : @ui.Container) -> Module {
  let countset = @graphics.Charset::new(
    @resource.ui_loader().load_res(["Basic.img", "ItemNo"]),
    @graphics.CharsetAlignment::LEFT,
  )
  { countset, container }
}

pub fn make_handlers(
  self : Module,
  charlook_getter : () -> @character.CharLook?,
  inventory_getter : () -> @inventory.Inventory?
) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [
    (
      OPEN_NPC_SHOP,
      OpenNpcShopHandler::new(self, charlook_getter, inventory_getter),
    ),
  ]
}
