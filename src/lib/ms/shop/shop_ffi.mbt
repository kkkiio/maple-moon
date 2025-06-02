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
  let listener = fn(npc_shop : OpenNpcShop?) {
    guard npc_shop is Some(npc_shop) else {
      return callback(@js.Nullable::null())
    }
    let shop_data = {
      npc_id: npc_shop.npc_id,
      shop_items: npc_shop.items.mapi(fn(i, item) {
        let item_data = @item.ItemData::get_async(item.id)
        {
          slot_no: i,
          item_id: item.id,
          name: item_data
          .poll()
          .bind(fn(item_data) { item_data.to_option() })
          .map(fn(item_data) { item_data.name })
          .or_default(),
          price: item.price,
          icon: item_data
          .poll()
          .bind(fn(item_data) { item_data.to_option() })
          .bind(fn(item_data) { item_data.get_icon(false).bitmap })
          .map(fn(bitmap) { bitmap.image })
          .or(@resource.Image::new_pending()),
          buyable_qty: item.buyable,
        }
      }),
    }
    callback(@js.Nullable::from_option(Some(shop_data)))
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
