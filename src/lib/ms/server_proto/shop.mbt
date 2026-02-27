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
} derive(Show, ToJson, FromJson)

///|
/// Server message that opens NPC shop UI with items.
pub(all) struct OpenNpcShopMessage {
  npc_id : Int
  items : Array[ShopItem]
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for OpenNpcShopMessage with type_code() {
  @net.Opcode::OPEN_NPC_SHOP.int_value()
}

///|
/// Server message for transaction confirmation code.
pub(all) struct ConfirmShopTransactionMessage {
  code : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for ConfirmShopTransactionMessage with type_code() {
  @net.Opcode::CONFIRM_SHOP_TRANSACTION.int_value()
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
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for NpcShopActionMessage with type_code() {
  @net.ClientOpcode::NPC_SHOP_ACTION.int_value()
}
