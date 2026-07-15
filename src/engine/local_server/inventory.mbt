///|
pub(all) struct StorageEquipData {
  item_id : Int
  slot : Int
  stats : Map[String, Int]
  slots : Int
  level : Int
  itemlevel : Int
  itemexp : Int
  vicious : Int
} derive(Debug, Default, ToJson, @json.FromJson)

///|
pub(all) struct StorageItemData {
  item_id : Int
  slot : Int
  count : Int
} derive(Debug, Default, ToJson, @json.FromJson)

///|
pub(all) enum StorageItemEntry {
  Equip(StorageEquipData)
  Item(StorageItemData)
} derive(Debug, ToJson, @json.FromJson)

///|
pub fn StorageItemEntry::from_server_proto(
  entry : @server_proto.InventoryItemEntry,
) -> StorageItemEntry {
  match entry {
    Equip(
      id~,
      slot~,
      stats~,
      slots~,
      level~,
      itemlevel~,
      itemexp~,
      vicious~,
      ..
    ) => {
      let eq_data : StorageEquipData = {
        item_id: id,
        slot,
        stats: {
          let map = Map([])
          for k, v in stats.0 {
            map.set(k.name(), v)
          }
          map
        },
        slots,
        level,
        itemlevel,
        itemexp,
        vicious,
      }
      StorageItemEntry::Equip(eq_data)
    }
    Item(id~, slot~, count~, ..) =>
      StorageItemEntry::Item({ item_id: id, slot, count })
    Pet(id~, slot~, ..) =>
      StorageItemEntry::Item({ item_id: id, slot, count: 1 })
  }
}

///|
pub fn StorageItemEntry::to_server_proto(
  self : StorageItemEntry,
  invtype : @server_proto.InventoryType,
) -> @server_proto.InventoryItemEntry {
  match self {
    Equip(eq) => {
      let stats : @resource.EnumMap[@maple_stat.EquipStatId, Int] = Default::default()
      for k, v in eq.stats {
        if @maple_stat.EquipStatId::from_name(k) is Some(stat_id) {
          stats.0.set(stat_id, v)
        }
      }

      @server_proto.InventoryItemEntry::Equip(
        invtype~,
        slot=eq.slot,
        id=eq.item_id,
        cash=false,
        expire=0,
        slots=eq.slots,
        level=eq.level,
        stats~,
        owner="",
        flag=0,
        itemlevel=eq.itemlevel,
        itemexp=eq.itemexp,
        vicious=eq.vicious,
      )
    }
    Item(it) =>
      @server_proto.InventoryItemEntry::Item(
        invtype~,
        slot=it.slot,
        id=it.item_id,
        cash=false,
        expire=0,
        count=it.count,
        owner="",
        flag=0,
      )
  }
}

///|
pub fn LocalServer::load_character_inventory_tab_data(
  self : LocalServer,
  data : Json,
) -> Unit {
  match data {
    { "invtype": Number(invtype_num, ..), "items": Array(items_json), .. } => {
      let invtype_opt = @server_proto.InventoryType::by_value(
        invtype_num.to_int(),
      )
      guard invtype_opt is Some(invtype) else { return }

      // Update revision if provided
      match data {
        { "revision": Number(revision, ..), .. } =>
          if revision.to_int() > self.character_revision {
            self.character_revision = revision.to_int()
          }
        _ => ()
      }

      guard self.player_items.get(invtype) is Some(tab_items) else { return }
      tab_items.clear()
      for item_json in items_json {
        let storage_entry : StorageItemEntry = @json.from_json(item_json) catch {
          err => {
            @log.error("Failed to parse StorageItemEntry", data={
              "error": err.to_string(),
              "json": @log.JsonValue(item_json),
            })
            continue
          }
        }
        let proto_entry = storage_entry.to_server_proto(invtype)
        let slot = match proto_entry {
          Equip(slot~, ..) => slot
          Item(slot~, ..) => slot
          Pet(slot~, ..) => slot
        }
        tab_items.set(slot, proto_entry)
      }
    }
    _ => ()
  }
}

///|
pub fn LocalServer::save_character_inventory_data(
  self : LocalServer,
  character_id : Int,
  revision : Int,
) -> Unit {
  for invtype in inventory_tabs() {
    guard self.player_items.get(invtype) is Some(tab_items) else { continue }
    let items_array : Array[Json] = []
    for _slot, item_entry in tab_items {
      let storage_entry = StorageItemEntry::from_server_proto(item_entry)
      items_array.push(ToJson::to_json(storage_entry))
    }
    self.db.save_json(
      character_inventory_store_name,
      character_inventory_tab_key(character_id, invtype),
      {
        "character_id": character_id,
        "revision": revision,
        "invtype": invtype.int_value(),
        "slot_max": self.slot_max_by_tab.get(invtype).unwrap_or(0),
        "items": items_array,
      },
    )
  }
}
