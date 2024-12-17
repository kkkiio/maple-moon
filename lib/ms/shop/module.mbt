///|
struct Module {
  countset : @graphics.Charset
  container : @ui.Container
  shop2_res : @resource.NxNode
  mut shop_ui : UIShop?
}

///|
pub fn Module::load(container : @ui.Container) -> @utils.Future[Module] {
  @ui.ui_window_2_loader().load_res(["Shop2"])
  |> @utils.map(fn(src) { Module::new(container, src) })
}

///|
fn Module::new(
  container : @ui.Container,
  shop2_res : @resource.NxNode
) -> Module {
  let countset = @graphics.Charset::new(
    @ui.common_ui_loader().load_res(["Basic.img", "ItemNo"]),
    @graphics.CharsetAlignment::LEFT,
  )
  { countset, container, shop2_res, shop_ui: None }
}

///|
pub fn make_handlers(
  self : Module,
  charlook_getter : () -> @char_look.CharLook?,
  inventory_getter : () -> @inventory.Inventory?
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      OPEN_NPC_SHOP,
      @net.with_log(
        OPEN_NPC_SHOP,
        fn(recv) {
          handle_open_npc_shop!(self, charlook_getter, inventory_getter, recv)
        },
      ),
    ),
    @net.make_handler(
      CONFIRM_SHOP_TRANSACTION,
      fn(recv) -> Int! { recv.read_byte!() },
      fn(code) { handle_confirm_shop_transaction(self, code) },
      log_recv=true,
    ),
  ]
  |> Map::from_array
}
