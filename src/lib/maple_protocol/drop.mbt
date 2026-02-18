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
  @net.Opcode::DROP_LOOT.int_value()
}

///|
pub(all) struct RemoveLootMessage {
  mode : Int
  oid : Int
  cid : Int?
} derive(Show, ToJson, FromJson)

///|
pub impl ServerMessage for RemoveLootMessage with type_code() {
  @net.Opcode::REMOVE_LOOT.int_value()
}
