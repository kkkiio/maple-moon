///|
fn get_all_items_by_type(mod : Module, t : TypeId) -> Array[ItemUIData] {
  mod.inventory.inventories[t]
  .values()
  .filter_map(fn(it) {
    match @item.ItemData::get_async(it.item_id).poll() {
      Some(Ok(item_data)) =>
        Some({
          id: it.item_id,
          name: item_data.name,
          icon: item_data.get_icon(false).bitmap.map_or(
            @resource.Image::new_pending(),
            fn(bitmap) { bitmap.image },
          ),
        })
      Some(Err(e)) => {
        @log.error(
          { "err": e.to_string(), "item_id": it.item_id },
          "Failed to load item data",
        )
        None
      }
      None => None // TODO: return async result
    }
  })
  .to_array()
}

///| Type for inventory change watcher callback
typealias InventoryWatcher = (Array[ItemUIData]) -> Bool

///|
pub struct ItemUIData {
  id : Int
  name : String
  icon : @resource.Image
}

///| Watch inventory changes for a specific kind of items
pub fn watch_inventory_by_kind(
  mod : Module,
  kind : String,
  watcher : InventoryWatcher
) -> Unit {
  let type_id = match kind {
    "equip" => TypeId::EQUIP
    "use" => TypeId::USE
    "setup" => TypeId::SETUP
    "etc" => TypeId::ETC
    "cash" => TypeId::CASH
    "equipped" => TypeId::EQUIPPED
    _ => {
      @log.error({ "kind": kind }, "watch_inventory_by_kind: invalid kind")
      return
    }
  }

  // Call watcher with initial items
  let items = get_all_items_by_type(mod, type_id)
  let cont = watcher(items)
  if not(cont) {
    return
  }

  // Add to inventory listeners
  mod.inventory.listen_item_changes(type_id, fn() {
    let items = get_all_items_by_type(mod, type_id)
    watcher(items)
  })
}
