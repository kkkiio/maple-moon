///|
/// Item-use intent emitted by inventory UI interactions.
pub(all) enum ItemUseIntent {
  /// Try equipping one item from `EQUIP` tab.
  TryEquip(
    type_id~ : @server_proto.InventoryType,
    slot_no~ : Int,
    item_id~ : Int
  )
  /// Try using one item from `USE` tab.
  TryUse(type_id~ : @server_proto.InventoryType, slot_no~ : Int, item_id~ : Int)
} derive(Show, ToJson)

///|
let queue_ref : Ref[Array[ItemUseIntent]] = Ref::new([])

///|
/// Push one item-use intent into queue.
pub fn push_intent(intent : ItemUseIntent) -> Unit {
  queue_ref.val.push(intent)
}

///|
/// Drain all queued intents and clear queue in one step.
pub fn drain_intents() -> Array[ItemUseIntent] {
  let intents = queue_ref.val
  queue_ref.val = []
  intents
}

///|
/// Clear all pending intents.
pub fn clear_intents() -> Unit {
  queue_ref.val = []
}
