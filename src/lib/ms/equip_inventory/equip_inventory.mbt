///|
/// Per-frame system that consumes all pending item-use intents.
pub fn equip_inventory_system(_world : @ecs.World) -> Unit {
  let intents = @item_use_events.drain_intents()
  for intent in intents {
    match intent {
      TryEquip(type_id~, slot_no~, item_id~) =>
        handle_try_equip(type_id, slot_no, item_id)
      TryUse(type_id~, slot_no~, item_id~) =>
        handle_try_use(type_id, slot_no, item_id)
    }
  }
}

///|
fn handle_try_equip(
  type_id : @server_proto.InventoryType,
  slot_no : Int,
  item_id : Int,
) -> Unit {
  if type_id != @server_proto.InventoryType::EQUIP {
    @log.warn("ignore non-EQUIP try_equip", data={
      "type_id": type_id,
      "slot_no": slot_no,
      "item_id": item_id,
    })
    return
  }
  let inv = @inventory.inventory.val
  guard inv.get_slot_item_at(type_id, slot_no) is Some(slot_item) else {
    return
  }
  if slot_item.item_id != item_id {
    return
  }
  guard @player.get_player() is Some(player) else { return }
  let item_data = @item.request_item_data(item_id)
  let equip_data = @equip_data.EquipData::parse_item_data(item_data) catch {
    e => {
      @log.error("failed to parse equip data", data={
        "error": e,
        "item_id": item_id,
      })
      return
    }
  }
  match can_wear_equip(player, equip_data) {
    Some(reason) => {
      @log.info("reject equip request", data={
        "reason": reason,
        "item_id": item_id,
        "slot_no": slot_no,
      })
      return
    }
    None => ()
  }
  let equip_message : @server_proto.MoveItemMessage = {
    invtype: type_id,
    slot: slot_no,
    action: -@inventory.find_equip_slot(inv, equip_data).int_value(),
    qty: 1,
  }
  @game_server.send(equip_message)
}

///|
fn handle_try_use(
  type_id : @server_proto.InventoryType,
  slot_no : Int,
  item_id : Int,
) -> Unit {
  if type_id != @server_proto.InventoryType::USE {
    @log.warn("ignore non-USE try_use", data={
      "type_id": type_id,
      "slot_no": slot_no,
      "item_id": item_id,
    })
    return
  }
  let inv = @inventory.inventory.val
  if inv.get_item_id(type_id, slot_no) != item_id {
    return
  }
  @game_server.send(@server_proto.UseItemMessage::{ slot_no, item_id })
}

///|
fn can_wear_equip(
  player : @player.Player,
  _equip_data : @equip_data.EquipData,
) -> String? {
  let alerted = player.character.is_alerted()
  if alerted {
    return Some("character is alerted")
  }
  None
}
