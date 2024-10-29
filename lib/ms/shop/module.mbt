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
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
  [
    (
      OPEN_NPC_SHOP,
      @net.with_log(
        OPEN_NPC_SHOP,
        fn(recv : @net.InPacket) {
          handle_open_npc_shop!(self, charlook_getter, inventory_getter, recv)
        }
      ),
    ),
  ]
}
