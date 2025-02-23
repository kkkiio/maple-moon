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
          count: if t == TypeId::EQUIP {
            1
          } else {
            it.count
          },
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

///|
pub fn use_item(mod : Module, kind : String, slot : Int) -> String {
  let type_id = get_type_id_by_kind?(kind).unwrap()
  match type_id {
    TypeId::EQUIP => {
      guard let Some(player) = (mod.player_getter)() else { None => return "" }
      guard let Some(item_data) = mod.inventory.get_item_at_slot(type_id, slot) else {
        None => return ""
      }
      let equip_data = @equip_data.EquipData::from_item_data?(item_data).unwrap() // TODO: handle error
      match can_wear_equip(player, equip_data) {
        Some(hint) => return hint
        None => ()
      }
      new_equip_item_packet(slot, mod.inventory.find_equipslot(equip_data)).dispatch()
    }
    TypeId::USE => {
      let item_id = mod.inventory.get_item_id(type_id, slot)
      if item_id <= 0 {
        return "not found item id at slot \{slot} of \{kind}"
      }
      mod.packet_processor.send_message({ slot, itemid: item_id })
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
    // TODO: alert
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
  let mut i = 0
  if reqLevel > stats.get_stat(@maple_stat.Id::LEVEL) {
    i += 1
  } else if reqDEX > stats.get_total(@equip_stat.Id::DEX) {
    i += 1
  } else if reqSTR > stats.get_total(@equip_stat.Id::STR) {
    i += 1
  } else if reqLUK > stats.get_total(@equip_stat.Id::LUK) {
    i += 1
  } else if reqINT > stats.get_total(@equip_stat.Id::INT) {
    i += 1
  } else if reqFAME > 0 { // TODO: support honor
    i += 1
  }
  if i > 0 {
    // TODO: show hint message
    return Some("not enough stats")
  }
  None
}
