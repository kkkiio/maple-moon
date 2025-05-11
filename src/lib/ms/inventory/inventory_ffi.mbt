///|
fn get_all_items_by_type(mod : Module, kind : TypeId) -> Array[UISlot] {
  let slotmax = mod.inventory.get_slotmax(kind)
  (1)
  .until(slotmax, inclusive=true)
  .map(fn(slot_no) {
    match mod.inventory.get_slot_item_at(kind, slot_no) {
      Some(slot_item) =>
        match @item.ItemData::get_async(slot_item.item_id).poll() {
          Some(Ok(item_data)) =>
            Some({
              slot_no,
              id: item_data.item_id,
              name: item_data.name,
              desc: if kind is TypeId::EQUIP || kind is TypeId::EQUIPPED {
                make_equip_desc(item_data)
              } else {
                make_html_desc(item_data.desc)
              },
              count: if kind == TypeId::EQUIP {
                1
              } else {
                mod.inventory.get_item_count(kind, slot_no)
              },
              icon: item_data.get_icon(false).bitmap.map_or(
                @resource.Image::new_pending(),
                fn(bitmap) { bitmap.image },
              ),
            })
          Some(Err(e)) => {
            @log.error(
              {
                "err": e.to_string(),
                "item_id": slot_item.item_id,
                "slot": slot_no,
              },
              "Failed to load item data",
            )
            Some({
              slot_no,
              id: slot_item.item_id,
              name: "Unknown \{slot_item.item_id}",
              desc: "",
              count: slot_item.count,
              icon: @resource.Image::new_pending(),
            })
          }
          None => None // TODO: return async result
        }
      None => None
    }
  })
  .to_array()
}

///|
typealias UISlot = WithItemSlot? // Slot in UI may be empty

///| Type for inventory change watcher callback
typealias InventoryWatcher = (Array[UISlot]) -> Bool

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
fn get_type_id_by_kind(kind : String) -> TypeId! {
  match kind {
    "equip" => TypeId::EQUIP
    "use" => TypeId::USE
    "setup" => TypeId::SETUP
    "etc" => TypeId::ETC
    "cash" => TypeId::CASH
    "equipped" => TypeId::EQUIPPED
    _ => fail!("Invalid inventory kind: \{kind}")
  }
}

///| Watch inventory changes for a specific kind of items
pub fn watch_inventory_by_kind(
  mod : Module,
  kind : String,
  watcher : InventoryWatcher
) -> Unit {
  let type_id = get_type_id_by_kind?(kind).unwrap()
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

///| Watch meso changes
pub fn watch_meso(mod : Module, watcher : (Int) -> Bool) -> Unit {
  let cont = watcher(mod.inventory.get_meso())
  if not(cont) {
    return
  }
  mod.inventory.listen_meso_changes(watcher)
}

///|
pub fn use_item_at(mod : Module, kind : String, slot_no : SlotNo) -> String {
  guard get_type_id_by_kind?(kind) is Ok(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  match type_id {
    TypeId::EQUIP => {
      guard (mod.player_getter)() is Some(player) else { return "" }
      guard mod.inventory.get_slot_item_at(type_id, slot_no._) is Some(item) else {
        return "no item at slot \{slot_no} of \{kind}"
      }
      guard @item.ItemData::get_async(item.item_id).poll()
        is Some(Ok(item_data)) else {
        return "failed to load item data \{item.item_id}"
      }
      guard @equip_data.EquipData::parse_item_data?(item_data) is Ok(equip_data) else {
        return "failed to parse equip data \{item.item_id}"
      }
      match can_wear_equip(player, equip_data) {
        Some(hint) => return hint
        None => ()
      }
      let equip_message : EquipItemMessage = {
        src: slot_no._,
        dest: find_equip_slot(mod.inventory, equip_data),
      }
      mod.network.send_message(equip_message)
    }
    TypeId::USE => {
      let item_id = mod.inventory.get_item_id(type_id, slot_no._)
      if item_id <= 0 {
        return "not found item id at slot \{slot_no} of \{kind}"
      }
      mod.network.send_message({ slot_no: slot_no._, itemid: item_id })
    }
    _ => ()
  }
  return ""
}

///|
fn can_wear_equip(
  player : @player.Player,
  equip_data : @equip_data.EquipData
) -> String? {
  let look = player.character.get_look()
  let alerted = look.get_alerted()
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

///| Drop an item
pub fn drop_item(
  mod : Module,
  kind : String,
  index : Int,
  count : Int
) -> String {
  guard get_type_id_by_kind?(kind) is Ok(type_id) else {
    return "unknown inventory kind \{kind}"
  }
  if type_id is TypeId::CASH {
    return "You can't drop this item."
  }
  let slot_no = index + 1
  mod.network.send_message({ type_id, slot: slot_no, action: 0, qty: count })
  ""
}

///| Packet which requests that an item is moved
priv struct MoveItemPacket {
  type_id : TypeId
  slot : Int
  action : Int
  qty : Int
} derive(Show)

///|
impl @net.OutMessage for MoveItemPacket with pack(self) -> @net.OutPacket {
  @net.OutPacket::new(@net.ClientOpcode::MOVE_ITEM)
  ..write_time()
  ..write_byte(self.type_id.int_value().to_byte())
  ..write_short(self.slot)
  ..write_short(self.action)
  ..write_short(self.qty)
}

///|
fn make_html_desc(desc : String) -> String {
  desc.replace_all(old="\\n", new="<br/>")
}

///| Make equip description
/// show req stats and incr stats
fn make_equip_desc(item_data : @item.ItemData) -> String {
  guard @equip_data.EquipData::parse_item_data?(item_data) is Ok(equip_data) else {
    return ""
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
        _ => "Unknown"
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
