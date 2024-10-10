struct OpenNpcShopHandler {}

impl @net.PacketHandler for OpenNpcShopHandler with handle(
  self : OpenNpcShopHandler,
  recv : @net.InPacket
) -> Unit! {
  fail!("Not implemented")
}
// let npcid = recv.read_int!();
// let oshop = UI::get().get_element<UIShop>();

// if (!oshop) {
//     return;
// }

// UIShop &shop = *oshop;

// shop.reset(npcid);

// int16_t size = recv.read_short();

// for (int i = 0; i < size; i++) {
//     int32_t itemid = recv.read_int();
//     int32_t price = recv.read_int();
//     int32_t pitch = recv.read_int();
//     int32_t time = recv.read_int();

//     recv.skip(4);

//     bool norecharge = recv.read_short() == 1;

//     if (norecharge) {
//         int16_t buyable = recv.read_short();

//         shop.add_item(itemid, price, pitch, time, buyable);
//     } else {
//         recv.skip(4);

//         int16_t rechargeprice = recv.read_short();
//         int16_t slotmax = recv.read_short();

//         shop.add_rechargable(itemid,
//                              price,
//                              pitch,
//                              time,
//                              rechargeprice,
//                              slotmax);
//     }
// }
