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
    "items": [["Item", { "slot": 2, "item_id": 2000000, "count": 3 }]],
  })
  db.save_json(inventory_store, etc_key, {
    "character_id": 1,
    "revision": 1,
    "invtype": 4,
    "slot_max": 96,
    "items": [["Item", { "slot": 1, "item_id": 4000000, "count": 1 }]],
  })
  db.save_json(meta_store, meta_key, {
    "version": 2,
    "character_id": 1,
    "revision": 1,
    "updated_segment": "full",
  })

  let writer = LocalServer::new(db~)
  let _ = writer.load_character(character_id)
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
    "items": [["Item", { "item_id": 2000000, "slot": 2, "count": 3 }]],
  })
  json_inspect(etc_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "invtype": 4,
    "slot_max": 96,
    "items": [["Item", { "item_id": 4000000, "slot": 1, "count": 1 }]],
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
  let _ = reader.load_character(character_id)
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
    "items": [["Item", { "item_id": 2000000, "slot": 2, "count": 3 }]],
  })
  json_inspect(resaved_etc_snapshot, content={
    "character_id": 1,
    "revision": 3,
    "invtype": 4,
    "slot_max": 96,
    "items": [["Item", { "item_id": 4000000, "slot": 1, "count": 1 }]],
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

///|
async test "local server consumes use item and emits modify inventory" {
  let character_id = 1
  let db = MemoryDB::new()
  db.save_json("character_inventory", "char:\{character_id}:inventory:2", {
    "character_id": 1,
    "revision": 1,
    "invtype": 2,
    "slot_max": 96,
    "items": [["Item", { "slot": 2, "item_id": 2000000, "count": 3 }]],
  })
  let server = LocalServer::new(db~)
  server.init_routes()
  let _ = server.load_character(character_id)
  let modified : Ref[Array[@server_proto.ModifyInventoryMessage]] = Ref::new([])
  server.add_server_message_handler(
    "test_use_item_modify",
    @net.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : @server_proto.ModifyInventoryMessage = @json.from_json(json)
      modified.val.push(msg)
    },
  )
  server.send_client_message(@server_proto.UseItemMessage::{
    slot_no: 2,
    item_id: 2000000,
  })
  server_system(server)
  server_system(server)
  inspect(modified.val.length(), content="1")
  inspect(modified.val[0].mods.length(), content="1")
  inspect(modified.val[0].movement is None, content="true")
  match modified.val[0].mods[0] {
    { mode: @server_proto.ModifyInventoryMode::CHANGE_COUNT, t, pos, arg, .. } => {
      inspect(t == @server_proto.InventoryType::USE, content="true")
      inspect(pos, content="2")
      inspect(arg, content="2")
    }
    _ => fail("expect use item change count mod")
  }
}

///|
async test "local server equips item and emits source plus equipped updates" {
  let character_id = 1
  let db = MemoryDB::new()
  db.save_json("character_inventory", "char:\{character_id}:inventory:1", {
    "character_id": 1,
    "revision": 1,
    "invtype": 1,
    "slot_max": 96,
    "items": [
      [
        "Equip",
        {
          "slot": 3,
          "item_id": 1060002,
          "stats": {},
          "slots": 7,
          "level": 0,
          "itemlevel": 0,
          "itemexp": 0,
          "vicious": 0,
        },
      ],
    ],
  })
  let server = LocalServer::new(db~)
  server.init_routes()
  let _ = server.load_character(character_id)
  let modified : Ref[Array[@server_proto.ModifyInventoryMessage]] = Ref::new([])
  server.add_server_message_handler(
    "test_move_item_modify",
    @net.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : @server_proto.ModifyInventoryMessage = @json.from_json(json)
      modified.val.push(msg)
    },
  )
  server.send_client_message(@server_proto.MoveItemMessage::{
    invtype: @server_proto.InventoryType::EQUIP,
    slot: 3,
    action: -5,
    qty: 1,
  })
  server_system(server)
  server_system(server)
  inspect(modified.val.length(), content="1")
  inspect(modified.val[0].mods.length(), content="1")
  inspect(modified.val[0].movement.unwrap(), content="2")
  match modified.val[0].mods[0] {
    { mode: @server_proto.ModifyInventoryMode::SWAP, t, pos, arg, .. } => {
      inspect(t == @server_proto.InventoryType::EQUIP, content="true")
      inspect(pos, content="3")
      inspect(arg, content="-5")
    }
    _ => fail("expect equip swap mod")
  }
}

///|
async test "local server equip swap survives save and reload" {
  let character_id = 1
  let db = MemoryDB::new()
  db.save_json("character_core", "char:\{character_id}:core", {
    "character_id": character_id,
    "revision": 1,
    "map_id": 100000001,
    "portal_id": 0,
    "meso": 1000000,
  })
  db.save_json("character_inventory", "char:\{character_id}:inventory:1", {
    "character_id": character_id,
    "revision": 1,
    "invtype": 1,
    "slot_max": 96,
    "items": [
      [
        "Equip",
        {
          "slot": 1,
          "item_id": 1462000,
          "stats": {},
          "slots": 7,
          "level": 0,
          "itemlevel": 0,
          "itemexp": 0,
          "vicious": 0,
        },
      ],
    ],
  })
  let server = LocalServer::new(db~)
  server.init_routes()
  let _ = server.load_character(character_id)
  server.send_client_message(@server_proto.MoveItemMessage::{
    invtype: @server_proto.InventoryType::EQUIP,
    slot: 1,
    action: -11,
    qty: 1,
  })
  server_system(server)
  server_system(server)
  server.save_character_inventory(character_id)

  guard db.get_json("character_inventory", "char:\{character_id}:inventory:1")
    is Some(equip_tab_snapshot) else {
    fail("missing equip tab snapshot")
  }
  guard db.get_json("character_inventory", "char:\{character_id}:inventory:-1")
    is Some(equipped_tab_snapshot) else {
    fail("missing equipped tab snapshot")
  }
  json_inspect(equip_tab_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "invtype": 1,
    "slot_max": 96,
    "items": [],
  })
  json_inspect(equipped_tab_snapshot, content={
    "character_id": 1,
    "revision": 2,
    "invtype": -1,
    "slot_max": 0,
    "items": [
      [
        "Equip",
        {
          "item_id": 1462000,
          "slot": 11,
          "stats": {},
          "slots": 7,
          "level": 0,
          "itemlevel": 0,
          "itemexp": 0,
          "vicious": 0,
        },
      ],
    ],
  })

  let reader = LocalServer::new(db~)
  let loaded = reader.load_character(character_id)
  inspect(loaded, content="true")
  reader.save_character_inventory(character_id)
  guard db.get_json("character_inventory", "char:\{character_id}:inventory:-1")
    is Some(reloaded_equipped_snapshot) else {
    fail("missing reloaded equipped tab snapshot")
  }
  json_inspect(reloaded_equipped_snapshot, content={
    "character_id": 1,
    "revision": 3,
    "invtype": -1,
    "slot_max": 0,
    "items": [
      [
        "Equip",
        {
          "item_id": 1462000,
          "slot": 11,
          "stats": {},
          "slots": 7,
          "level": 0,
          "itemlevel": 0,
          "itemexp": 0,
          "vicious": 0,
        },
      ],
    ],
  })
}
