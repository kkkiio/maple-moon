///|
pub fn look_sync_system(_world : @ecs.World) -> Unit {
  guard @player.get_player() is Some(player) else { return }
  let look = player.character.look
  let inventory = @inventory.inventory.val

  let equipped_tab = @inventory.TypeId::EQUIPPED

  // Track which slots we've seen in inventory
  let inventory_slots = Map::new()
  let mut add_or_update_count = 0
  let mut remove_count = 0

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
        Some(data) => {
          @log.info("look_sync_apply_equip", data={
            "slot_id": slot_id.int_value(),
            "inventory_item_id": item.item_id,
            "current_look_item_id": current_id,
          })
          look.add_equip(data, slot_id) catch {
            _ => ()
          }
          add_or_update_count = add_or_update_count + 1
        }
        None => () // Will try again next frame
      }
    }
  }

  // Check for removals
  let look_equips = look.get_equips().iter().to_array()
  for slot_tuple in look_equips {
    let (slot_id, _) = slot_tuple
    if !inventory_slots.contains(slot_id) {
      @log.info("look_sync_remove_equip", data={
        "slot_id": slot_id.int_value(),
      })
      look.remove_equip(slot_id)
      remove_count = remove_count + 1
    }
  }

  if add_or_update_count > 0 || remove_count > 0 {
    @log.info("look_sync_summary", data={
      "add_or_update_count": add_or_update_count,
      "remove_count": remove_count,
      "stance": look.get_stance(),
      "frame": look.get_frame(),
    })
  }
}
