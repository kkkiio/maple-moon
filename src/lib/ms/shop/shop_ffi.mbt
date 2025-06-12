///|
pub struct SellableItemUIData {
  slot_no : SlotNo
  item_id : Int
  name : String
  price : Int
  icon : @resource.Image
  buyable_qty : Int
}

///|
pub struct ShopUIData {
  npc_id : Int
  shop_items : Array[SellableItemUIData]
}

///| 
pub fn watch_opening_shop_ffi(
  mod : Module,
  callback : (@js.Nullable[ShopUIData]) -> Bool
) -> Unit {
  let mut cont = true
  let listener = fn(npc_shop : OpenNpcShop?) {
    guard npc_shop is Some(npc_shop) else {
      return callback(@js.Nullable::null())
    }
    async fn async_callback!() {
      let shop_data = {
        npc_id: npc_shop.npc_id,
        shop_items: npc_shop.items.mapi(fn(i, item) {
          async fn() {
            let item_data = @item.ItemData::get_async(
              item.id,
              mod.string_loader,
            )
            {
              slot_no: i,
              item_id: item.id,
              name: item_data.name,
              price: item.price,
              icon: item_data.get_icon(false).bitmap.map_or(
                @resource.Image::new_pending(),
                fn(bitmap) { bitmap.image },
              ),
              buyable_qty: item.buyable,
            }
          }
        })
        |> @js.async_all(),
      }
      cont = callback(@js.Nullable::from_option(Some(shop_data)))
    }

    if cont {
      mod.io_service.execute(async_callback)
    }
    cont
  }
  if not(listener(mod.opening_shop)) {
    return
  }
  mod.opening_shop_listeners.push(listener)
}

///|
pub fn watch_confirm_shop_transaction_ffi(
  mod : Module,
  callback : (String) -> Bool
) -> Unit {
  mod.confirm_shop_transaction_listeners.push(fn(code) {
    callback(code.to_string())
  })
}

///|
pub fn buy_shop_item_ffi(
  mod : Module,
  slot : SlotNo,
  item_id : Int,
  qty : Int
) -> Unit {
  mod.network.send_message(
    ShopActionMessage::Item(slot=slot._, item_id~, qty~, buy=true),
  )
}

///|
pub fn sell_inventory_item_ffi(
  mod : Module,
  slot : @inventory.SlotNo,
  item_id : Int,
  qty : Int
) -> Unit {
  mod.network.send_message(
    ShopActionMessage::Item(slot=slot._, item_id~, qty~, buy=false),
  )
}

///|
pub fn leave_shop_ffi(mod : Module) -> Unit {
  mod.leave_shop()
}

///| Shop Slot number. starts from 0
type SlotNo Int derive(Eq, Hash, Show, ToJson)

///|
let mode_BUY : Byte = b'\x00'

///|
let mode_SELL : Byte = b'\x01'

///|
let mode_RECHARGE : Byte = b'\x02'

///|
let mode_LEAVE : Byte = b'\x03'

///|
priv enum ShopActionMessage {
  Item(slot~ : Int, item_id~ : Int, qty~ : Int, buy~ : Bool) // Requests that an item should be bought from or sold to a NPC shop
  Recharge(slot~ : Int) // Requests that an item should be recharged at a NPC shop
  Leave // Requests exiting from a NPC shop
} derive(Show)

///|
impl @net.OutMessage for ShopActionMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::NPC_SHOP_ACTION)
  match self {
    ShopActionMessage::Item(slot~, item_id~, qty~, buy~) => {
      packet
      ..write_byte(if buy { mode_BUY } else { mode_SELL })
      ..write_short(slot)
      ..write_int(item_id)
      ..write_short(qty)
      packet
    }
    ShopActionMessage::Recharge(slot~) => {
      packet..write_byte(mode_RECHARGE)..write_short(slot)
      packet
    }
    ShopActionMessage::Leave => {
      packet..write_byte(mode_LEAVE)
      packet
    }
  }
}
