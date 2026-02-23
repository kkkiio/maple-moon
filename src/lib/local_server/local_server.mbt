///|
using @server_proto {
  type ChangeStatsMesoMessage,
  trait ClientMessage,
  trait ServerMessage,
  type ChangeMapMessage,
  type DropLootMessage,
  type ModifyInventoryItemMessage,
  type PickupItemMessage,
  type ShowStatusMesoGainMessage,
  type MoveMonsterMessage,
  type SetFieldMessage,
  type SelectCharMessage,
  type MobSpawnControllerMessage,
  type StatsEntry,
  type InventoryEntry,
  type InventoryItemEntry,
  type PlayerQuestLogInfo,
  type InventoryType,
}

///|
using @resource {get_mapx_loader}

///|
pub let default_rand_seed : Ref[Bytes] = Ref::new(
  b"0123456789abcdef0123456789abcdef",
)

///|
/// A local server implementation for playing the game offline.
///
/// Although there is a open-source server implementation `Cosmic`,
/// it is burdensome to implement the full client features, so we implement a local server here to play the game offline.
///
/// We can use the built-in resource loader in `@resource` package to load the resources and implement the server logic here.
struct LocalServer {
  client_message_queue : @queue.Queue[(Int, Json)]
  server_message_queue : @queue.Queue[(Int, Json)]
  client_message_handler_map : Map[Int, (Json) -> Unit raise]
  server_message_handlers_map : Map[Int, Array[(String, (Json) -> Unit raise)]]
  mut last_map_id : Int
  mut last_portal_id : Int
  mut last_object_id : Int
  mut spawn_batch_id : Int
  mut map_transfer_ready : Bool
  mut player_meso : Int
  mut current_character_id : Int
  mut character_revision : Int
  player_items : Map[InventoryType, Map[Int, (Int, Int)]]
  slot_max_by_tab : Map[InventoryType, Int]
  mobs : Map[Int, ServerMob]
  drops : Map[Int, DropLootMessage]
  pending_mob_spawns : Array[PendingMobSpawn]
  db : &DB
  mut drop_db : MobDropDatabase?
  mut global_drop_db : MobDropDatabase?
  drop_rng : @random.Rand
}

///|
priv struct ServerMob {
  id : Int
  x : Int
  y : Int
  mut hp : Int
  max_hp : Int
}

///|
priv struct PendingMobSpawn {
  msg : MobSpawnControllerMessage
  max_hp : Int
}

///|
pub fn LocalServer::new(
  db~ : &DB,
  drop_rng? : @random.Rand = @random.Rand::chacha8(seed=default_rand_seed.val),
) -> LocalServer {
  {
    client_message_queue: @queue.new(),
    server_message_queue: @queue.new(),
    client_message_handler_map: {},
    server_message_handlers_map: {},
    last_map_id: 100000000,
    last_portal_id: 0,
    last_object_id: 100000,
    spawn_batch_id: 0,
    map_transfer_ready: false,
    player_meso: 0,
    current_character_id: 1,
    character_revision: 0,
    player_items: {
      let m : Map[InventoryType, Map[Int, (Int, Int)]] = Map::new()
      m.set(InventoryType::EQUIP, Map::new())
      m.set(InventoryType::USE, Map::new())
      m.set(InventoryType::SETUP, Map::new())
      m.set(InventoryType::ETC, Map::new())
      m.set(InventoryType::CASH, Map::new())
      m
    },
    slot_max_by_tab: {
      let m : Map[InventoryType, Int] = Map::new()
      m.set(InventoryType::EQUIP, 96)
      m.set(InventoryType::USE, 96)
      m.set(InventoryType::SETUP, 96)
      m.set(InventoryType::ETC, 96)
      m.set(InventoryType::CASH, 96)
      m
    },
    mobs: Map::new(),
    drops: Map::new(),
    pending_mob_spawns: Array::new(),
    db,
    drop_db: None,
    global_drop_db: None,
    drop_rng,
  }
}

///|
pub fn init_server(server : LocalServer) -> Unit {
  server.init_routes()
  // 加载掉落数据库
  server.load_drop_databases()
}

///|
pub fn LocalServer::init_routes(self : LocalServer) -> Unit {
  self.client_message_handler_map[@net.ClientOpcode::SELECT_CHAR.int_value()] = v => {
    self.on_select_char(v)
  }
  self.client_message_handler_map[@net.ClientOpcode::CHANGE_MAP.int_value()] = v => {
    self.on_change_map(v)
  }
  self.client_message_handler_map[@net.ClientOpcode::PLAYER_MAP_TRANSFER.int_value()] = _ => {
    self.map_transfer_ready = true
    self.flush_pending_mob_spawns()
  }
  self.client_message_handler_map[@net.ClientOpcode::CLOSE_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@net.ClientOpcode::RANGED_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@net.ClientOpcode::MAGIC_ATTACK.int_value()] = v => {
    self.on_mob_damage(v)
  }
  self.client_message_handler_map[@net.ClientOpcode::MOVE_MONSTER.int_value()] = json => {
    let msg : MoveMonsterMessage = @json.from_json(json)
    match self.mobs.get(msg.oid) {
      Some(mob) =>
        self.mobs.set(msg.oid, { ..mob, x: msg.start_pos.x, y: msg.start_pos.y })
      None => ()
    }
  }
  self.client_message_handler_map[@net.ClientOpcode::PICKUP_ITEM.int_value()] = json => {
    self.on_pickup_item(json)
  }
}

///|
/// send client message to the server
#callsite(autofill(loc))
pub fn[T : ClientMessage] LocalServer::send_client_message(
  self : LocalServer,
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(
    log_level,
    "send_client_message",
    data={ "message": @log.JsonValue(json) },
    loc~,
  )
  self.client_message_queue.push((type_code, json))
}

///|
fn LocalServer::on_mob_damage(self : LocalServer, json : Json) -> Unit raise {
  let msg : @server_proto.MobDamageMessage = @json.from_json(json)
  guard self.mobs.get(msg.oid) is Some(mob) else { return }
  mob.hp -= msg.damage
  if mob.hp <= 0 {
    mob.hp = 0
    self.send_server_message(@server_proto.KillMobMessage::{
      oid: msg.oid,
      animation: 1,
    })
    // 生成掉落
    self.spawn_drops_for_mob(mob)
    self.mobs.remove(msg.oid)
  } else {
    let percent = (mob.hp.to_double() / mob.max_hp.to_double() * 100.0).to_int()
    self.send_server_message(@server_proto.MobHpMessage::{
      oid: msg.oid,
      percent,
    })
  }
}

///|
/// 为怪物生成掉落
/// 
/// WORKAROUND: skip equip items before we implement the equip data preloading.
fn LocalServer::spawn_drops_for_mob(
  self : LocalServer,
  mob : ServerMob,
) -> Unit {
  let (messages, next_oid) = calculate_mob_drops(
    mob.id,
    mob.x,
    mob.y,
    self.last_object_id,
    self.drop_db,
    self.global_drop_db,
    self.drop_rng,
  )
  for msg in messages {
    if not(msg.meso) &&
      InventoryType::by_item_id(msg.item_id) == Some(InventoryType::EQUIP) {
      continue
    }
    self.drops.set(msg.oid, msg)
    self.send_server_message(msg)
  }
  self.last_object_id = next_oid
}

///|
fn LocalServer::on_pickup_item(self : LocalServer, json : Json) -> Unit raise {
  let msg : PickupItemMessage = @json.from_json(json)
  guard self.drops.get(msg.oid) is Some(drop) else { return }
  if drop.meso {
    let gain = drop.item_id
    self.player_meso += gain
    self.save_character_core_snapshot()
    self.send_server_message(ChangeStatsMesoMessage::{ meso: self.player_meso })
    self.send_server_message(ShowStatusMesoGainMessage::{ gain, })
    self.drops.remove(msg.oid) |> ignore
    self.send_server_message(@server_proto.RemoveLootMessage::{
      mode: 2,
      oid: msg.oid,
      cid: Some(1),
    })
    return
  }
  guard self.apply_pickup_item(drop.item_id) else { return }
  self.save_character_inventory_snapshot()
  self.drops.remove(msg.oid) |> ignore
  self.send_server_message(@server_proto.RemoveLootMessage::{
    mode: 2,
    oid: msg.oid,
    cid: Some(1),
  })
}

///|
fn LocalServer::apply_pickup_item(self : LocalServer, item_id : Int) -> Bool {
  guard InventoryType::by_item_id(item_id) is Some(invtype) else {
    return false
  }
  guard self.player_items.get(invtype) is Some(tab_items) else { return false }
  let stackable = invtype != InventoryType::EQUIP
  if stackable {
    for slot, it in tab_items {
      let (existing_item_id, existing_count) = it
      if existing_item_id == item_id {
        let next_count = existing_count + 1
        tab_items.set(slot, (item_id, next_count))
        self.send_server_message(ModifyInventoryItemMessage::{
          item: InventoryItemEntry::Item(
            invtype~,
            slot~,
            id=item_id,
            cash=false,
            expire=0,
            count=next_count,
            owner="",
            flag=0,
          ),
        })
        return true
      }
    }
  }
  guard find_next_empty_slot(
      tab_items,
      self.slot_max_by_tab.get(invtype).unwrap_or(0),
    )
    is Some(slot) else {
    return false
  }
  tab_items.set(slot, (item_id, 1))
  self.send_server_message(ModifyInventoryItemMessage::{
    item: InventoryItemEntry::Item(
      invtype~,
      slot~,
      id=item_id,
      cash=false,
      expire=0,
      count=1,
      owner="",
      flag=0,
    ),
  })
  true
}

///|
fn find_next_empty_slot(items : Map[Int, (Int, Int)], slot_max : Int) -> Int? {
  for slot in 1..<=slot_max {
    if not(items.contains(slot)) {
      return Some(slot)
    }
  }
  None
}

///|
fn LocalServer::reset_player_inventory_state(self : LocalServer) -> Unit {
  self.player_meso = 0
  for _, items in self.player_items {
    items.clear()
  }
}

///|
fn LocalServer::save_character_core_snapshot(self : LocalServer) -> Unit {
  @io_service.execute_background(
    async fn() { self.save_character_core(self.current_character_id) },
    on_error=fn(err) {
      @log.error("failed to save character core snapshot", data={ "error": err })
    },
  )
}

///|
fn LocalServer::save_character_inventory_snapshot(self : LocalServer) -> Unit {
  @io_service.execute_background(
    async fn() { self.save_character_inventory(self.current_character_id) },
    on_error=fn(err) {
      @log.error("failed to save character inventory snapshot", data={
        "error": err,
      })
    },
  )
}

///|
fn LocalServer::bump_character_revision(self : LocalServer) -> Int {
  self.character_revision += 1
  self.character_revision
}

///|
fn LocalServer::append_inventory_entries(
  self : LocalServer,
  items : Array[InventoryItemEntry],
) -> Unit {
  for invtype, tab_items in self.player_items {
    if invtype == InventoryType::EQUIP || invtype == InventoryType::EQUIPPED {
      continue
    }
    for slot, item in tab_items {
      let (item_id, count) = item
      items.push(
        InventoryItemEntry::Item(
          invtype~,
          slot~,
          id=item_id,
          cash=false,
          expire=0,
          count~,
          owner="",
          flag=0,
        ),
      )
    }
  }
}

///|
fn LocalServer::spawn_mobs_for_map(self : LocalServer, map_id : Int) -> Unit {
  self.spawn_batch_id += 1
  let batch_id = self.spawn_batch_id
  self.map_transfer_ready = false
  self.mobs.clear()
  self.drops.clear()
  self.pending_mob_spawns.clear()
  @io_service.execute_background(async fn() {
    let loader = get_mapx_loader()
    let prefix = (map_id / 100000000).to_string()
    let strid = @utils.stoi_left_pad0(map_id, 9)
    let path = ["Map\{prefix}", "\{strid}.img"]
    let node_res = loader.load_res_async(path)
    guard node_res.value() is { "life": Object(life_map), .. } else { return }
    for _, entity in life_map {
      if self.spawn_batch_id != batch_id {
        return
      }
      match entity {
        {
          "type": String("m"),
          "id": String(id_str),
          "x": Number(x, ..),
          "y": Number(y, ..),
          "f": Number(f, ..),
          "fh": Number(fh, ..),
          ..
        } => {
          let monster_id = @strconv.parse_int(id_str)
          self.last_object_id += 1
          let spawn_msg = MobSpawnControllerMessage::{
            oid: self.last_object_id,
            id: monster_id,
            mode: 1, // Passive Control
            x: x.to_int(),
            y: y.to_int(),
            stance: f.to_int(),
            fh: fh.to_int(),
            team: -1,
          }
          let mob_loader = @resource.get_mob_loader()
          let mob_strid = @utils.stoi_left_pad0(monster_id, 7)
          let mob_path = ["\{mob_strid}.img"]
          let mob_node = mob_loader.load_res_async(mob_path)
          guard mob_node.value()
            is { "info": { "maxHP": Number(max_hp, ..), .. }, .. } else {
            continue
          }
          self.pending_mob_spawns.push({
            msg: spawn_msg,
            max_hp: max_hp.to_int(),
          })
        }
        _ => ()
      }
    }
    if self.map_transfer_ready && self.spawn_batch_id == batch_id {
      self.flush_pending_mob_spawns()
    }
  })
}

///|
fn LocalServer::flush_pending_mob_spawns(self : LocalServer) -> Unit {
  for pending in self.pending_mob_spawns {
    self.send_server_message(pending.msg)
    let server_mob = ServerMob::{
      id: pending.msg.id,
      x: pending.msg.x,
      y: pending.msg.y,
      hp: pending.max_hp,
      max_hp: pending.max_hp,
    }
    self.mobs.set(pending.msg.oid, server_mob)
  }
  self.pending_mob_spawns.clear()
}

///|
#callsite(autofill(loc))
fn[T : ServerMessage] LocalServer::send_server_message(
  self : LocalServer,
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(
    log_level,
    "send_server_message",
    data={ "type_code": @log.HexInt(type_code), "json": @log.JsonValue(json) },
    loc~,
  )
  self.server_message_queue.push((type_code, json))
}

///|
pub fn LocalServer::add_server_message_handler(
  self : LocalServer,
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  self.server_message_handlers_map
  .get_or_init(type_code, fn() { Array::new() })
  .push((name, handler))
}

///|
pub fn server_system(server : LocalServer) -> Unit {
  while server.server_message_queue.pop() is Some((type_code, json)) {
    @log.debug("receive server message", data={
      "type_code": @log.HexInt(type_code),
      "json": @log.JsonValue(json),
    })
    guard server.server_message_handlers_map.get(type_code) is Some(handlers) else {
      continue
    }
    for handler in handlers {
      (handler.1)(json) catch {
        err =>
          @log.error("Error handling server message", data={
            "error": err.to_string(),
            "name": handler.0,
          })
      }
    }
  }
  while server.client_message_queue.pop() is Some((type_code, json)) {
    guard server.client_message_handler_map.get(type_code) is Some(handler) else {
      @log.debug("Missing client message handler", data={
        "type_code": @log.HexInt(type_code),
        "json": @log.JsonValue(json),
      })
      return
    }
    handler(json) catch {
      err => abort("Error handling client message: \{err.to_string()}")
    }
  }
}

///|
/// 通过 JS fetch 加载文本
extern "js" fn fetch_text(path : String) -> @js.Promise =
  #| (p) => fetch(p).then((res) => res.text())

///|
/// 加载怪物掉落数据库
fn LocalServer::load_drop_databases(self : LocalServer) -> Unit {
  // 加载怪物特定掉落
  @io_service.execute_background(async fn() {
    let text : String = fetch_text("/assets/data/mob_drops.csv").wait()
      |> @js.Value::cast
    self.drop_db = Some(MobDropDatabase::from_csv(text))
    @log.info("Loaded mob_drops.csv", data={})
  })
  // 加载全局掉落
  @io_service.execute_background(async fn() {
    let text : String = fetch_text("/assets/data/drop_data_global.csv").wait()
      |> @js.Value::cast
    self.global_drop_db = Some(MobDropDatabase::from_csv(text))
    @log.info("Loaded drop_data_global.csv", data={})
  })
}
