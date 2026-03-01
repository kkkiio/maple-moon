///|
pub fn look_sync_system(_delta : Double) -> Unit {
  guard @player.get_player() is Some(player) else { return }
  let look = player.character.look
  let inventory = @inventory.inventory.val

  let equipped_tab = @inventory.TypeId::EQUIPPED

  // Track which slots we've seen in inventory
  let inventory_slots = Map::new()

  // Use equip-slot semantic range instead of slot_max(EQUIPPED).
  // Some SetField payloads do not carry EQUIPPED slotmax explicitly.
  for slot in 1..<@slot.Id::length() {
    guard inventory.get_slot_item_at(equipped_tab, slot) is Some(item) else {
      continue
    }
    let slot_id = @slot.Id::from_int(slot)
    inventory_slots.set(slot_id, item.item_id)

    let current_id = look.get_equips().get_equip(slot_id)
    if current_id != item.item_id {
      // Need change
      match @item.request_item_data_if_ready(item.item_id) {
        Some(data) => look.add_equip(data, slot_id) catch { _ => () }
        None => () // Will try again next frame
      }
    }
  }

  // Check for removals
  let look_equips = look.get_equips().iter().to_array()
  for slot_tuple in look_equips {
    let (slot_id, _) = slot_tuple
    if not(inventory_slots.contains(slot_id)) {
      look.remove_equip(slot_id)
    }
  }
}
