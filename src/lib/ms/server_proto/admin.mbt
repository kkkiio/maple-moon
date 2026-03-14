/// Messages for local admin/debug commands.

///|
/// Client request for local admin/debug actions.
///
/// This message is handled by local server only.
pub(all) enum AdminCommandMessage {
  /// Set current character mesos to a fixed value.
  SetMeso(meso~ : Int)
  /// Add an item into current character inventory.
  AddItem(item_id~ : Int, quantity~ : Int)
  /// Warp current character to target map and portal id.
  Warp(map_id~ : Int, portal_id~ : Int)
} derive(Show, ToJson, FromJson)

///|
pub impl ClientMessage for AdminCommandMessage with type_code() {
  ClientOpcode::ADMIN_COMMAND.int_value()
}
