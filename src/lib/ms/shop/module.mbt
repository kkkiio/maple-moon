///|
struct Module {
  network : @net.Network
  mut opening_shop : OpenNpcShop?
  opening_shop_listeners : Array[(OpenNpcShop?) -> Bool]
  confirm_shop_transaction_listeners : Array[
    (ConfirmShopTransactionCode) -> Bool,
  ]
  string_loader : @resource.SyncLoader
}

///|
pub fn Module::load(
  network : @net.Network,
  string_loader : @resource.SyncLoader
) -> Module {
  // @ui.ui_window_2_loader().load_res(["Shop2"])
  // |> @utils.map(fn(src) { Module::new(container, src) })
  Module::new(network, string_loader)
}

///|
fn Module::new(
  network : @net.Network,
  string_loader : @resource.SyncLoader
) -> Module {
  // let countset = @graphics.Charset::new(
  //   @ui.common_ui_loader().load_res(["Basic.img", "ItemNo"]),
  //   @graphics.CharsetAlignment::LEFT,
  // )
  {
    network,
    opening_shop_listeners: [],
    confirm_shop_transaction_listeners: [],
    opening_shop: None,
    string_loader,
  }
}

///|
pub fn make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(
      OPEN_NPC_SHOP,
      parse_open_npc_shop,
      fn(shop : OpenNpcShop) {
        self.opening_shop = Some(shop)
        self.opening_shop_listeners.retain(fn(listener) { listener(Some(shop)) })
      },
      log_recv=true,
    ),
    @net.make_handler(
      CONFIRM_SHOP_TRANSACTION,
      fn(recv : @net.InPacket) {
        let code = recv.read_byte!()
        match code {
          0 => ConfirmShopTransactionCode::Ok
          1 => ConfirmShopTransactionCode::NotEnoughInStock
          2 => ConfirmShopTransactionCode::NotEnoughMesos
          3 => ConfirmShopTransactionCode::InventoryFull
          5 => ConfirmShopTransactionCode::NotEnoughInStock
          6 | 7 => ConfirmShopTransactionCode::DueToError
          8 => ConfirmShopTransactionCode::Ok
          13 => ConfirmShopTransactionCode::NotEnoughItems
          _ => fail!("Unknown confirm shop transaction code: \{code}")
        }
      },
      fn(code) {
        self.confirm_shop_transaction_listeners.retain(fn(listener) {
          listener(code)
        })
      },
      log_recv=true,
    ),
  ]
  |> Map::from_array
}

///|
pub enum ConfirmShopTransactionCode {
  Ok
  NotEnoughMesos
  InventoryFull
  NotEnoughInStock
  DueToError
  NotEnoughItems
} derive(Show)

///|
fn Module::leave_shop(self : Module) -> Unit {
  self.network.send_message(ShopActionMessage::Leave)
  self.opening_shop = None
  self.opening_shop_listeners.retain(fn(listener) { listener(None) })
}
