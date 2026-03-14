/// Messages for map drops.

///|
pub(all) struct DropLootMessage {
  mode : Int
  oid : Int
  meso : Bool
  item_id : Int
  owner : Int
  pickuptype : Int
  dropto : @struct.Point[Int]
  dropfrom : @struct.Point[Int]
  player_drop : Bool
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for DropLootMessage with type_code() {
  Opcode::DROP_LOOT.int_value()
}

///|
pub(all) struct RemoveLootMessage {
  mode : Int
  oid : Int
  cid : Int?
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for RemoveLootMessage with type_code() {
  Opcode::REMOVE_LOOT.int_value()
}

///|
/// Client request for picking up a ground drop.
pub(all) struct PickupItemMessage {
  oid : Int
  position : @struct.Point[Int]
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for PickupItemMessage with type_code() {
  ClientOpcode::PICKUP_ITEM.int_value()
}

///|
/// Local-server CHANGE_STATS (meso only) sync event.
pub(all) struct ChangeStatsMesoMessage {
  meso : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for ChangeStatsMesoMessage with type_code() {
  Opcode::CHANGE_STATS.int_value()
}

///|
/// Local-server SHOW_STATUS_INFO (meso gain) sync event.
pub(all) struct ShowStatusMesoGainMessage {
  gain : Int
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for ShowStatusMesoGainMessage with type_code() {
  Opcode::SHOW_STATUS_INFO.int_value()
}

///|
/// Local-server MODIFY_INVENTORY mod mode.
pub(all) enum ModifyInventoryMode {
  ADD
  CHANGE_COUNT
  SWAP
  REMOVE
  ADD_COUNT
} derive(Show, ToJson, FromJson)

///|
/// Local-server MODIFY_INVENTORY single mod entry.
pub(all) struct ModifyInventoryMod {
  mode : ModifyInventoryMode
  t : InventoryType
  pos : Int
  arg : Int
  item : InventoryItemEntry?
} derive(Show, ToJson, FromJson)

///|
/// Local-server MODIFY_INVENTORY sync event (batch + movement).
pub(all) struct ModifyInventoryMessage {
  mods : Array[ModifyInventoryMod]
  movement : Int?
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for ModifyInventoryMessage with type_code() {
  Opcode::MODIFY_INVENTORY.int_value()
}
