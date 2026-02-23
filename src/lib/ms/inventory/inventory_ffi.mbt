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
  if not(cont) {
    return
  }
  mod.inventory.listen_meso_changes(watcher)
}

///|
pub fn use_item_at(
  mod : Module,
  kind : String,
  slot_no : SlotNo,
  _args : Array[String],
) -> String {
  guard get_type_id_by_kind(kind) is Some(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  match type_id {
    TypeId::EQUIP => {
      guard (mod.player_getter)() is Some(player) else { return "" }
      guard mod.inventory.get_slot_item_at(type_id, slot_no.0) is Some(item) else {
        return "no item at slot \{slot_no} of \{kind}"
      }
      let item_data = @item.request_item_data(item.item_id)
      let equip_data = @equip_data.EquipData::parse_item_data(item_data) catch {
        e => return "failed to parse equip data: \{e}, id=\{item.item_id}"
      }
      match can_wear_equip(player, equip_data) {
        Some(hint) => return hint
        None => ()
      }
      let equip_message : EquipItemMessage = {
        src: slot_no.0,
        dest: find_equip_slot(mod.inventory, equip_data),
      }
      mod.network.send_message(equip_message)
      ""
    }
    TypeId::USE => {
      let item_id = mod.inventory.get_item_id(type_id, slot_no.0)
      if item_id <= 0 {
        return "not found item id at slot \{slot_no} of \{kind}"
      }
      mod.network.send_message(UseItemMessage::new(slot_no.0, item_id))
      ""
    }
    _ => return "not supported kind \{kind}"
  }
}

///|
fn can_wear_equip(
  player : @player.Player,
  equip_data : @equip_data.EquipData,
) -> String? {
  let alerted = player.character.is_alerted()
  if alerted {
    return Some("character is alerted")
  }
  let stats = player.get_stats()
  let reqGender = equip_data.get_gender()
  let female = stats.get_female()
  match reqGender {
    0 => // Male
      if female {
        return Some("required gender is male")
      }
    1 => // Female
      if not(female) {
        return Some("required gender is female")
      }
    2 => () // Unisex
    _ => panic() // unknown gender
  }
  let reqLevel = equip_data.get_reqstat(@maple_stat.Id::LEVEL)
  let reqDEX = equip_data.get_reqstat(@maple_stat.Id::DEX)
  let reqSTR = equip_data.get_reqstat(@maple_stat.Id::STR)
  let reqLUK = equip_data.get_reqstat(@maple_stat.Id::LUK)
  let reqINT = equip_data.get_reqstat(@maple_stat.Id::INT)
  let reqFAME = equip_data.get_reqstat(@maple_stat.Id::FAME)
  let hints = []
  let level = stats.get_stat(@maple_stat.Id::LEVEL)
  if reqLevel > level {
    hints.push("require level \{reqLevel} but got \{level}")
  }
  let dex = stats.get_total(@maple_stat.EquipStatId::DEX)
  if reqDEX > dex {
    hints.push("require dex \{reqDEX} but got \{dex}")
  }
  let str = stats.get_total(@maple_stat.EquipStatId::STR)
  if reqSTR > str {
    hints.push("require str \{reqSTR} but got \{str}")
  }
  let luk = stats.get_total(@maple_stat.EquipStatId::LUK)
  if reqLUK > luk {
    hints.push("require luk \{reqLUK} but got \{luk}")
  }
  let int = stats.get_total(@maple_stat.EquipStatId::INT)
  if reqINT > int {
    hints.push("require int \{reqINT} but got \{int}")
  }
  let fame = 0 // TODO: support honor
  if reqFAME > fame {
    hints.push("require fame \{reqFAME} but got \{fame}")
  }
  if hints.is_empty() {
    None
  } else {
    Some(hints.join(", "))
  }
}

///|
/// Drop an item
pub fn drop_item(
  mod : Module,
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
  mod.network.send_message({ type_id, slot: slot_no, action: 0, qty: count })
  ""
}

///|
/// Packet which requests that an item is moved
priv struct MoveItemPacket {
  type_id : TypeId
  slot : Int
  action : Int
  qty : Int
} derive(Show)

///|
impl @net.OutMessage for MoveItemPacket with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::MOVE_ITEM)
  packet
  ..write_time()
  ..write_byte(self.type_id.int_value().to_byte())
  ..write_short(self.slot)
  ..write_short(self.action)
  .write_short(self.qty)
  packet
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
