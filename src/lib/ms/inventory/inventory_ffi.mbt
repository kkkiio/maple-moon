///|
async fn get_all_items_by_type(mod : Module, kind : TypeId) -> Array[UISlot] {
  let slotmax = mod.inventory.get_slotmax(kind)
  let items : Array[UISlot] = []
  for slot_no in 1..<=slotmax {
    match mod.inventory.get_slot_item_at(kind, slot_no) {
      Some(slot_item) => {
        let item_data = @item.ItemData::load_item_data(slot_item.item_id)
        let desc = if kind is TypeId::EQUIP || kind is TypeId::EQUIPPED {
          make_equip_desc(item_data)
        } else {
          make_html_desc(item_data.desc)
        }
        let count = if kind == TypeId::EQUIP { 1 } else { slot_item.count }
        let icon = @resource.Image::new_pending()
        items.push(
          Some({
            slot_no: SlotNo(slot_no),
            id: item_data.item_id,
            name: item_data.name,
            desc,
            count,
            icon,
          }),
        )
      }
      None => items.push(None)
    }
  }
  items
}

///|
type UISlot = WithItemSlot? // Slot in UI may be empty

///|
/// Type for inventory change watcher callback
type InventoryWatcher = (Array[UISlot]) -> Bool

///|
pub struct WithItemSlot {
  slot_no : SlotNo
  id : Int
  name : String
  desc : String
  count : Int
  icon : @resource.Image
}

///|
fn get_type_id_by_kind(kind : String) -> TypeId? {
  let type_id = match kind {
    "equip" => TypeId::EQUIP
    "use" => TypeId::USE
    "setup" => TypeId::SETUP
    "etc" => TypeId::ETC
    "cash" => TypeId::CASH
    "equipped" => TypeId::EQUIPPED
    _ => return None
  }
  Some(type_id)
}

///|
/// Watch inventory changes for a specific kind of items
pub fn watch_inventory_by_kind(
  mod : Module,
  kind : String,
  watcher : InventoryWatcher,
) -> String {
  guard get_type_id_by_kind(kind) is Some(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  let mut cont = true
  fn sync_callback() {
    if cont {
      @io_service.execute_background(async fn() {
        let items = get_all_items_by_type(mod, type_id)
        cont = watcher(items)
      })
    }
    cont
  }
  // Call watcher with initial items
  guard sync_callback()
  // Add to inventory listeners
  mod.inventory.listen_item_changes(type_id, sync_callback)
  ""
}

///|
/// Watch meso changes
pub fn watch_meso(mod : Module, watcher : (Int) -> Bool) -> Unit {
  let cont = watcher(mod.inventory.get_meso())
  if !cont {
    return
  }
  mod.inventory.listen_meso_changes(watcher)
}

///|
pub fn use_item_at(
  _mod : Module,
  kind : String,
  slot_no : SlotNo,
  _args : Array[String],
) -> String {
  guard get_type_id_by_kind(kind) is Some(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  use_item_at_slot(type_id, slot_no.0).unwrap_or("")
}

///|

///|
/// Drop an item
pub fn drop_item(
  _mod : Module,
  kind : String,
  slot_no : Int,
  count : Int,
) -> String {
  guard get_type_id_by_kind(kind) is Some(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  if type_id is TypeId::CASH {
    return "You can't drop this item."
  }
  @game_server.send(@server_proto.MoveItemMessage::{
    invtype: type_id,
    slot: slot_no,
    action: 0,
    qty: count,
  })
  ""
}

///|
fn make_html_desc(desc : String) -> String {
  desc.replace_all(old="\\n", new="<br/>")
}

///|
/// Make equip description
/// show req stats and incr stats
fn make_equip_desc(item_data : @item.ItemData) -> String {
  let equip_data = @equip_data.EquipData::parse_item_data(item_data) catch {
    e => return "failed to parse equip data: \{e}, id=\{item_data.item_id}"
  }
  let req_stats = equip_data.req_stats.iter2().to_array()
  req_stats.sort_by_key(fn(it) { it.0 })
  let incr_stats = equip_data.incr_stats.iter2().to_array()
  incr_stats.sort_by_key(fn(it) { it.0 })
  let buf = StringBuilder::new()
  buf.write_string("Requirements:<br/>")
  for stat in req_stats {
    let val = if stat.0 is @maple_stat.Id::JOB {
      let req_job = match stat.1 {
        0 => "Beginner"
        1 => "Warrior"
        2 => "Magician"
        4 => "Bowman"
        8 => "Thief"
        16 => "Pirate"
        v => v.to_string()
      }
      req_job
    } else {
      stat.1.to_string()
    }
    buf.write_string("\{stat.0} \{val}<br/>")
  }
  buf.write_string("Increases:<br/>")
  for stat in incr_stats {
    buf.write_string("\{stat.0} \{stat.1}<br/>")
  }
  buf.to_string()
}
