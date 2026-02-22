///|
async test "local server character snapshot roundtrip keeps inventory data" {
  let character_id = 1
  let core_store = "character_core"
  let inventory_store = "character_inventory"
  let meta_store = "character_meta"
  let core_key = "char:\{character_id}:core"
  let use_key = "char:\{character_id}:inventory:2"
  let etc_key = "char:\{character_id}:inventory:4"
  let meta_key = "char:\{character_id}:meta"

  let db = MemoryDB::new()
  db.save_json(core_store, core_key, {
    "character_id": 1,
    "revision": 1,
    "map_id": 100000001,
    "portal_id": 2,
    "meso": 500,
  })
  db.save_json(inventory_store, use_key, {
    "character_id": 1,
    "revision": 1,
    "invtype": 2,
    "slot_max": 96,
    "items": [{ "slot": 2, "item_id": 2000000, "count": 3 }],
  })
  db.save_json(inventory_store, etc_key, {
    "character_id": 1,
    "revision": 1,
    "invtype": 4,
    "slot_max": 96,
    "items": [{ "slot": 1, "item_id": 4000000, "count": 1 }],
  })
  db.save_json(meta_store, meta_key, {
    "version": 2,
    "character_id": 1,
    "revision": 1,
    "updated_segment": "full",
  })

  let writer = LocalServer::new(db~)
  writer.load_character(character_id)
  writer.save_character(character_id)

  guard db.get_json(core_store, core_key) is Some(core_snapshot) else {
    fail("missing core snapshot")
  }
  json_inspect(core_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "map_id": 100000001,
    "portal_id": 2,
    "meso": 500,
  })
  guard db.get_json(inventory_store, use_key) is Some(use_snapshot) else {
    fail("missing use inventory snapshot")
  }
  guard db.get_json(inventory_store, etc_key) is Some(etc_snapshot) else {
    fail("missing etc inventory snapshot")
  }
  json_inspect(use_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "invtype": 2,
    "slot_max": 96,
    "items": [{ "slot": 2, "item_id": 2000000, "count": 3 }],
  })
  json_inspect(etc_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "invtype": 4,
    "slot_max": 96,
    "items": [{ "slot": 1, "item_id": 4000000, "count": 1 }],
  })
  guard db.get_json(meta_store, meta_key) is Some(meta_snapshot) else {
    fail("missing meta snapshot")
  }
  json_inspect(meta_snapshot, content={
    "version": 2,
    "character_id": 1,
    "revision": 2,
    "updated_segment": "full",
  })

  let reader = LocalServer::new(db~)
  reader.load_character(character_id)
  reader.save_character_inventory(character_id)

  guard db.get_json(inventory_store, use_key) is Some(resaved_use_snapshot) else {
    fail("missing re-saved use inventory snapshot")
  }
  guard db.get_json(inventory_store, etc_key) is Some(resaved_etc_snapshot) else {
    fail("missing re-saved etc inventory snapshot")
  }
  json_inspect(resaved_use_snapshot, content={
    "character_id": 1,
    "revision": 3,
    "invtype": 2,
    "slot_max": 96,
    "items": [{ "slot": 2, "item_id": 2000000, "count": 3 }],
  })
  json_inspect(resaved_etc_snapshot, content={
    "character_id": 1,
    "revision": 3,
    "invtype": 4,
    "slot_max": 96,
    "items": [{ "slot": 1, "item_id": 4000000, "count": 1 }],
  })
  guard db.get_json(meta_store, meta_key) is Some(resaved_meta_snapshot) else {
    fail("missing re-saved meta snapshot")
  }
  json_inspect(resaved_meta_snapshot, content={
    "version": 2,
    "character_id": 1,
    "revision": 3,
    "updated_segment": "inventory",
  })
}
