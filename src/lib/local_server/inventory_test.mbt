///|
test "storage_item_entry_json" {
  let stats = Map::new()
  stats.set("WATK", 10)
  stats.set("STR", 5)

  let equip_data : @local_server.StorageItemEntry = @local_server.StorageItemEntry::Equip({
      item_id: 1302000,
      slot: -11,
      stats,
      slots: 7,
      level: 0,
      itemlevel: 0,
      itemexp: 0,
      vicious: 0,
    },
  )

  let json = equip_data.to_json()
  json_inspect(json, content=[
    "Equip",
    {
      "item_id": 1302000,
      "slot": -11,
      "stats": { "WATK": 10, "STR": 5 },
      "slots": 7,
      "level": 0,
      "itemlevel": 0,
      "itemexp": 0,
      "vicious": 0,
    },
  ])

  let item_data : @local_server.StorageItemEntry = @local_server.StorageItemEntry::Item({
      item_id: 2000000,
      slot: 1,
      count: 100,
    },
  )

  let item_json = item_data.to_json()
  json_inspect(item_json, content=[
    "Item",
    { "item_id": 2000000, "slot": 1, "count": 100 },
  ])
}
