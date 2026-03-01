/// Messages for inventory operations initiated by client.

///|
/// Client request for using one consumable item from `USE` tab.
pub(all) struct UseItemMessage {
  slot_no : Int
  item_id : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for UseItemMessage with type_code() {
  @net.ClientOpcode::USE_ITEM.int_value()
}

///|
/// Client request for moving/equipping inventory items.
///
/// `slot` and `action` follow Maple item-move packet semantics:
/// - `action < 0`: equip from inventory slot `slot` to equipped slot `-action`.
/// - `slot < 0 && action > 0`: unequip from equipped slot `-slot` to inventory slot `action`.
pub(all) struct MoveItemMessage {
  invtype : InventoryType
  slot : Int
  action : Int
  qty : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for MoveItemMessage with type_code() {
  @net.ClientOpcode::MOVE_ITEM.int_value()
}
