///|
struct StarterCharacterLoader {
  dummy : Unit
}

///|
fn StarterCharacterLoader::new() -> StarterCharacterLoader {
  { dummy: () }
}

///|
struct StarterStringLoader {
  dummy : Unit
}

///|
fn StarterStringLoader::new() -> StarterStringLoader {
  { dummy: () }
}

///|
struct EmptyItemLoader {
  dummy : Unit
}

///|
fn EmptyItemLoader::new() -> EmptyItemLoader {
  { dummy: () }
}

///|
struct EmptyMapxLoader {
  dummy : Unit
}

///|
fn EmptyMapxLoader::new() -> EmptyMapxLoader {
  { dummy: () }
}

///|
fn mock_icon(path : String) -> Json {
  { "__i": path, "__w": 1, "__h": 1, "origin": [0, 0] }
}

///|
fn mock_equip_entry() -> Json {
  {
    "info": {
      "icon": mock_icon("images/Item/mock_icon.png"),
      "iconRaw": mock_icon("images/Item/mock_icon_raw.png"),
    },
  }
}

///|
pub impl @resource.AsyncResourceLoader for StarterCharacterLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self.dummy)
  match path.to_owned() {
    "Coat/01040002.img" => mock_equip_entry()
    "Pants/01060002.img" => mock_equip_entry()
    "Shoes/01072001.img" => mock_equip_entry()
    "Weapon/01302000.img" => mock_equip_entry()
    other => fail("unexpected starter character path: \{other}")
  }
}

///|
pub impl @resource.AsyncResourceLoader for StarterStringLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self.dummy)
  match path.to_owned() {
    "Eqp.img" =>
      {
        "Eqp": {
          "Coat": { "1040002": { "name": "White Undershirt" } },
          "Pants": { "1060002": { "name": "Blue Jean Shorts" } },
          "Shoes": { "1072001": { "name": "Red Rubber Boots" } },
          "Weapon": { "1302000": { "name": "Sword" } },
        },
      }
    other => fail("unexpected starter string path: \{other}")
  }
}

///|
pub impl @resource.AsyncResourceLoader for EmptyItemLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self.dummy)
  fail("unexpected starter item path: \{path.to_owned()}")
}

///|
pub impl @resource.AsyncResourceLoader for EmptyMapxLoader with load_data(
  self,
  path,
) -> Json {
  ignore(self.dummy)
  let p = path.to_owned()
  if p.has_suffix("mx.json") {
    return { "tiled_path": "Map/Map1/100000000.img/map.tmj" }
  }
  if p.has_suffix("map.tmj") {
    return {
      "type": "map",
      "width": 1,
      "height": 1,
      "tilewidth": 1,
      "tileheight": 1,
      "layers": [
        {
          "id": 1,
          "name": "portal",
          "type": "objectgroup",
          "objects": [
            {
              "id": 1,
              "x": 0,
              "y": 0,
              "point": true,
              "properties": [
                { "name": "pn", "type": "string", "value": "sp" },
                { "name": "tm", "type": "int", "value": 100000000 },
                { "name": "tn", "type": "string", "value": "sp" },
                { "name": "pt", "type": "int", "value": 0 },
              ],
            },
          ],
        },
        { "id": 2, "name": "life", "type": "objectgroup", "objects": [] },
      ],
      "tilesets": [],
    }
  }
  fail("unexpected mapx path: \{p}")
}

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
    @server_proto.Opcode::MODIFY_INVENTORY.int_value(),
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
    @server_proto.Opcode::MODIFY_INVENTORY.int_value(),
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
    "revision": 3,
    "invtype": 1,
    "slot_max": 96,
    "items": [],
  })
  json_inspect(equipped_tab_snapshot, content={
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
    "revision": 4,
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

///|
async test "local server quest snapshot roundtrip keeps started and completed quests" {
  let character_id = 1
  let db = MemoryDB::new()
  let quest_key = "char:\{character_id}:quests"
  db.save_json("character_quest", quest_key, {
    "character_id": character_id,
    "revision": 7,
    "started": { "2084": "" },
    "completed": { "2083": 0, "2089": 0, "2091": 0 },
  })
  let writer = LocalServer::new(db~)
  let loaded = writer.load_character(character_id)
  inspect(loaded, content="true")
  writer.save_character_quest_data(character_id, 8)
  guard db.get_json("character_quest", quest_key) is Some(saved_quest_snapshot) else {
    fail("missing quest snapshot")
  }
  guard saved_quest_snapshot
    is {
      "revision": Number(revision, ..),
      "started": Object(started_map),
      "completed": Object(completed_map),
      ..
    } else {
    fail("quest snapshot format mismatch")
  }
  inspect(revision.to_int(), content="8")
  inspect(started_map.contains("2084"), content="true")
  inspect(started_map.contains("2083"), content="false")
  inspect(completed_map.contains("2083"), content="true")
  inspect(completed_map.contains("2089"), content="true")
}

///|
async test "local server forfeit quest emits QuestExpire and removes started quest" {
  let character_id = 1
  let db = MemoryDB::new()
  db.save_json("character_quest", "char:\{character_id}:quests", {
    "character_id": character_id,
    "revision": 1,
    "started": { "2091": "" },
    "completed": {},
  })
  let server = LocalServer::new(db~)
  server.init_routes()
  let _ = server.load_character(character_id)
  let updates : Ref[Array[@server_proto.UpdateQuestInfoMessage]] = Ref::new([])
  server.add_server_message_handler(
    "test_forfeit_success_update",
    @server_proto.Opcode::UPDATE_QUEST_INFO.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : @server_proto.UpdateQuestInfoMessage = @json.from_json(json)
      updates.val.push(msg)
    },
  )
  server.send_client_message(
    @server_proto.QuestActionMessage::ForfeitQuest(quest_id=2091),
  )
  server_system(server)
  server_system(server)
  server.save_character_quest_data(character_id, 2)
  guard db.get_json("character_quest", "char:\{character_id}:quests")
    is Some(saved_snapshot) else {
    fail("missing quest snapshot")
  }
  inspect(saved_snapshot is { "started": { }, .. }, content="true")
  inspect(updates.val.length(), content="1")
  inspect(
    updates.val[0]
    is @server_proto.UpdateQuestInfoMessage::QuestExpire(quest_id=2091),
    content="true",
  )
}

///|
async test "local server forfeit invalid quest emits QuestError and keeps state" {
  let character_id = 1
  let db = MemoryDB::new()
  db.save_json("character_quest", "char:\{character_id}:quests", {
    "character_id": character_id,
    "revision": 1,
    "started": { "2084": "" },
    "completed": {},
  })
  let server = LocalServer::new(db~)
  server.init_routes()
  let _ = server.load_character(character_id)
  let updates : Ref[Array[@server_proto.UpdateQuestInfoMessage]] = Ref::new([])
  server.add_server_message_handler(
    "test_forfeit_error_update",
    @server_proto.Opcode::UPDATE_QUEST_INFO.int_value(),
    fn(json : Json) -> Unit raise {
      let msg : @server_proto.UpdateQuestInfoMessage = @json.from_json(json)
      updates.val.push(msg)
    },
  )
  server.send_client_message(
    @server_proto.QuestActionMessage::ForfeitQuest(quest_id=2091),
  )
  server_system(server)
  server_system(server)
  server.save_character_quest_data(character_id, 2)
  guard db.get_json("character_quest", "char:\{character_id}:quests")
    is Some(saved_snapshot) else {
    fail("missing quest snapshot")
  }
  inspect(
    saved_snapshot is { "started": { "2084": "", .. }, .. },
    content="true",
  )
  inspect(updates.val.length(), content="1")
  inspect(
    updates.val[0]
    is @server_proto.UpdateQuestInfoMessage::QuestError(quest_id=2091),
    content="true",
  )
}
