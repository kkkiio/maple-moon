///|
pub struct ShopItem {
  id : Int
  price : Int
  pitch : Int
  time : Int
  charge_price : Int
  buyable : Int
} derive(Show, ToJson)

///|
pub struct OpenNpcShop {
  npc_id : Int
  items : Array[ShopItem]
} derive(Show, ToJson)

///|
pub fn parse_open_npc_shop(recv : @net.InPacket) -> OpenNpcShop raise {
  let npcid = recv.read_int()
  let size = recv.read_short()
  let items = []
  for i in 0..<size {
    let itemid = recv.read_int()
    let price = recv.read_int()
    let pitch = recv.read_int()
    let time = recv.read_int()
    recv.skip(4)
    let norecharge = recv.read_short() == 1
    if norecharge {
      let buyable = recv.read_short()
      items.push({ id: itemid, price, pitch, time, charge_price: 0, buyable })
    } else {
      recv.skip(4)
      let rechargeprice = recv.read_short()
      let slotmax = recv.read_short()
      items.push({
        id: itemid,
        price,
        pitch,
        time,
        charge_price: rechargeprice,
        buyable: slotmax,
      })
    }
  }
  { npc_id: npcid, items }
}

///|
// pub fn handle_open_npc_shop(mod : Module, shop : OpenNpcShop) -> Unit {
// mod.container.add_ui(
//   @ui.Element::new(
//     fn(hooks) {
//       let shop = UIShop::new(
//         {
//           countset: mod.countset,
//           charlook,
//           inventory,
//           npcid: shop.npcid,
//           shop_items: shop.items,
//         },
//         mod.shop2_res,
//         hooks,
//       )
//       for
//         t in [
//           @inventory.TypeId::EQUIP,
//           @inventory.TypeId::USE,
//           @inventory.TypeId::ETC,
//           @inventory.TypeId::SETUP,
//           @inventory.TypeId::CASH,
//         ] {
//         inventory.listen_item_changes(t, fn() {
//           guard shop.get_ui_model().is_active() else { return false }
//           shop.set_attributes()
//           true
//         })
//       }
//       mod.shop_ui = Some(shop)
//       shop
//     },
//     @ui.UIElementType::SHOP,
//     on_close=fn() { mod.shop_ui = None },
//   ),
//   true,
// )
// }
