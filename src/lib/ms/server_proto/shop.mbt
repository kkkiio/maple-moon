/// Messages for NPC shop interactions.

///|
/// One item entry inside NPC shop list.
pub(all) struct ShopItem {
  id : Int
  price : Int
  pitch : Int
  time : Int
  charge_price : Int
  buyable : Int
} derive(Debug, ToJson, FromJson)

///|
/// Server message that opens NPC shop UI with items.
pub(all) struct OpenNpcShopMessage {
  npc_id : Int
  items : Array[ShopItem]
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for OpenNpcShopMessage with type_code() {
  Opcode::OPEN_NPC_SHOP.int_value()
}

///|
/// Server message for transaction confirmation code.
pub(all) struct ConfirmShopTransactionMessage {
  code : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ServerMessage for ConfirmShopTransactionMessage with type_code() {
  Opcode::CONFIRM_SHOP_TRANSACTION.int_value()
}

///|
/// Client request to operate NPC shop.
///
/// `mode`: 0 buy, 1 sell, 2 recharge, 3 leave.
pub(all) struct NpcShopActionMessage {
  mode : Int
  slot : Int
  item_id : Int
  qty : Int
} derive(Debug, ToJson, FromJson)

///|
pub impl ClientMessage for NpcShopActionMessage with type_code() {
  ClientOpcode::NPC_SHOP_ACTION.int_value()
}
