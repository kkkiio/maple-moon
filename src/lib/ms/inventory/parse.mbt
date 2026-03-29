///|
pub fn handle_item(inventory : Inventory, item : InventoryItemEntry) -> Unit {
  match item {
    Equip(
      invtype~,
      slot~,
      id~,
      cash~,
      expire~,
      slots~,
      level~,
      stats~,
      owner~,
      flag~,
      itemlevel~,
      itemexp~,
      vicious~
    ) => {
      // Debug trace: verify how SetField inventory equip entries are ingested.
      @log.info("inventory_handle_item_equip", data={
        "invtype": invtype.to_json(),
        "slot": slot.to_json(),
        "item_id": id.to_json(),
      })
      inventory.add_equip(
        invtype,
        slot,
        id,
        cash,
        expire,
        slots,
        level,
        stats.0,
        owner,
        flag,
        itemlevel,
        itemexp,
        vicious,
      )
    }
    Pet(invtype~, slot~, id~, cash~, petname~) =>
      inventory.add_pet(invtype, slot, id, cash, petname)
    Item(invtype~, slot~, id~, cash~, expire~, count~, owner~, flag~) =>
      inventory.add_item(invtype, slot, id, cash, expire, count, owner, flag)
  }
}
