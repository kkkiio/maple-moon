///|
pub fn handle_open_npc_shop(
  mod : Module,
  charlook_getter : () -> @char_look.CharLook?,
  inventory_getter : () -> @inventory.Inventory?,
  recv : @net.InPacket
) -> Unit! {
  guard let Some(charlook) = charlook_getter() else { None => return }
  guard let Some(inventory) = inventory_getter() else { None => return }
  let npcid = recv.read_int!()
  let size = recv.read_short!()
  let shop_items = []
  for i in 0..<size {
    let itemid = recv.read_int!()
    let price = recv.read_int!()
    let pitch = recv.read_int!()
    let time = recv.read_int!()
    recv.skip!(4)
    let norecharge = recv.read_short!() == 1
    if norecharge {
      let buyable = recv.read_short!()
      shop_items.push({
        id: itemid,
        price,
        pitch,
        time,
        charge_price: 0,
        buyable,
      })
    } else {
      recv.skip!(4)
      let rechargeprice = recv.read_short!()
      let slotmax = recv.read_short!()
      shop_items.push({
        id: itemid,
        price,
        pitch,
        time,
        charge_price: rechargeprice,
        buyable: slotmax,
      })
    }
  }
  mod.container.add_ui(
    @ui.Element::new(
      fn(hooks) {
        let shop = UIShop::new(
          { countset: mod.countset, charlook, inventory, npcid, shop_items },
          mod.shop2_res,
          hooks,
        )
        inventory.listen_item_changes(fn() {
          guard shop.get_ui_model().is_active() else { return false }
          shop.set_attributes()
          true
        })
        mod.shop_ui = Some(shop)
        shop
      },
      @ui.UIElementType::SHOP,
      on_close=fn() { mod.shop_ui = None },
    ),
    true,
  )
}

///|
struct ShopItem {
  id : Int
  price : Int
  pitch : Int
  time : Int
  charge_price : Int
  buyable : Int
} derive(Show)

///|
pub fn handle_confirm_shop_transaction(mod : Module, code : Int) -> Unit {
  guard let Some(shop) = mod.shop_ui else { None => return }
  match code {
    0 | 8 => shop.set_attributes()
    _ => ()
  }
}
