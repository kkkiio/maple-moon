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

///|
/// Client request for picking up a ground drop.
pub(all) struct PickupItemMessage {
  oid : Int
  position : @struct.Point[Int]
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for PickupItemMessage with type_code() {
  @net.ClientOpcode::PICKUP_ITEM.int_value()
}

///|
pub impl @net.OutMessage for PickupItemMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::PICKUP_ITEM)
  packet.write_int(0)
  packet.write_byte((0).to_byte())
  packet.write_point(self.position)
  packet.write_int(self.oid)
  packet
}
