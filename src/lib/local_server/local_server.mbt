///|
using @maple_protocol {
  trait ClientMessage,
  trait ServerMessage,
  type ChangeMapMessage,
  type SetFieldMessage,
  type SelectCharMessage,
  type MobSpawnControllerMessage,
  type StatsEntry,
  type InventoryEntry,
  type PlayerQuestLogInfo,
  type InventoryType,
}

///|
/// A local server implementation for playing the game offline.
/// 
/// Although there is a open-source server implementation `Cosmic`, 
/// it is burdensome to implement the full client features, so we implement a local server here to play the game offline.
/// 
/// We can use the built-in resource loader in `@resource` package to load the resources and implement the server logic here.
/// 
/// We should not reference any game-packages(like `@map`, `@monster`, etc.) here to avoid circular dependencies.
priv struct LocalServer {
  client_message_queue : @queue.Queue[(Int, Json)]
  server_message_queue : @queue.Queue[(Int, Json)]
  client_message_handler_map : Map[Int, (Json) -> Unit raise]
  server_message_handlers_map : Map[Int, Array[(String, (Json) -> Unit raise)]]
  mut last_map_id : Int
  mut last_portal_id : Int
  mut last_object_id : Int
  mut spawn_batch_id : Int
  mut map_transfer_ready : Bool
  mobs : Map[Int, ServerMob]
  pending_mob_spawns : Array[PendingMobSpawn]
  mut db : IndexedDB?
}

///|
priv struct ServerMob {
  oid : Int
  id : Int
  mut hp : Int
  max_hp : Int
}

///|
priv struct PendingMobSpawn {
  msg : MobSpawnControllerMessage
  max_hp : Int
}

///|
fn LocalServer::new() -> LocalServer {
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
    mobs: Map::new(),
    pending_mob_spawns: Array::new(),
    db: None,
  }
}

///|
fn init {
  default_server.client_message_handler_map[@net.ClientOpcode::SELECT_CHAR.int_value()] = on_select_char
  default_server.client_message_handler_map[@net.ClientOpcode::CHANGE_MAP.int_value()] = default_server.on_change_map(
    _,
  )
  default_server.client_message_handler_map[@net.ClientOpcode::PLAYER_MAP_TRANSFER.int_value()] = fn(
    _,
  ) {
    default_server.map_transfer_ready = true
    default_server.flush_pending_mob_spawns()
  }
  default_server.client_message_handler_map[@net.ClientOpcode::CLOSE_ATTACK.int_value()] = on_mob_damage
  default_server.client_message_handler_map[@net.ClientOpcode::RANGED_ATTACK.int_value()] = on_mob_damage
  default_server.client_message_handler_map[@net.ClientOpcode::MAGIC_ATTACK.int_value()] = on_mob_damage
  default_server.client_message_handler_map[@net.ClientOpcode::MOVE_MONSTER.int_value()] = fn(
    _,
  ) {

  }
}

///|
using @resource {get_mapx_loader}

///|
fn on_mob_damage(json : Json) -> Unit raise {
  let msg : @maple_protocol.MobDamageMessage = @json.from_json(json)
  guard default_server.mobs.get(msg.oid) is Some(mob) else { return }
  mob.hp -= msg.damage
  if mob.hp <= 0 {
    mob.hp = 0
    default_server.send_server_message(@maple_protocol.KillMobMessage::{
      oid: msg.oid,
      animation: 1,
    })
    default_server.mobs.remove(msg.oid)
  } else {
    let percent = (mob.hp.to_double() / mob.max_hp.to_double() * 100.0).to_int()
    default_server.send_server_message(@maple_protocol.MobHpMessage::{
      oid: msg.oid,
      percent,
    })
  }
}

///|
fn LocalServer::spawn_mobs_for_map(self : LocalServer, map_id : Int) -> Unit {
  self.spawn_batch_id += 1
  let batch_id = self.spawn_batch_id
  self.map_transfer_ready = false
  self.mobs.clear()
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
      oid: pending.msg.oid,
      id: pending.msg.id,
      hp: pending.max_hp,
      max_hp: pending.max_hp,
    }
    self.mobs.set(pending.msg.oid, server_mob)
  }
  self.pending_mob_spawns.clear()
}

///|
let default_server : LocalServer = LocalServer::new()

///|
/// send client message to the server
#callsite(autofill(loc))
pub fn[T : ClientMessage] send(
  message : T,
  log_level? : @log.Level = @log.Level::DEBUG,
  loc~ : SourceLoc,
) -> Unit {
  let type_code = T::type_code()
  let json = message.to_json()
  @log.log(log_level, "send", data={ "message": json }, loc~)
  default_server.client_message_queue.push((type_code, json))
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
  @log.log(log_level, "send_server_message", data={ "message": json }, loc~)
  self.server_message_queue.push((type_code, json))
}

///|
pub fn add_server_message_handler(
  name : String,
  type_code : Int,
  handler : (Json) -> Unit raise,
) -> Unit {
  default_server.server_message_handlers_map
  .get_or_init(type_code, fn() { Array::new() })
  .push((name, handler))
}

///|
pub fn server_system(_delta : Double) -> Unit {
  while default_server.server_message_queue.pop() is Some((type_code, json)) {
    @log.debug("server message", data={ "type_code": type_code, "json": json })
    guard default_server.server_message_handlers_map.get(type_code)
      is Some(handlers) else {
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
  while default_server.client_message_queue.pop() is Some((type_code, json)) {
    guard default_server.client_message_handler_map.get(type_code)
      is Some(handler) else {
      @log.debug("Missing client message handler", data={
        "type_code": type_code,
        "json": json,
      })
      return
    }
    handler(json) catch {
      err => abort("Error handling client message: \{err.to_string()}")
    }
  }
}

///|
pub fn init_server() -> Unit {
  @io_service.execute_background(async fn() {
    let db = init_db()
    default_server.db = Some(db)
  })
}
