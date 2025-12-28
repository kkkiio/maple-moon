///|
using @maple_protocol {
  trait ClientMessage,
  trait ServerMessage,
  type ChangeMapMessage,
  type SetFieldMessage,
  type SelectCharMessage,
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
  mobs : Map[Int, ServerMob]
}

///|
priv struct ServerMob {
  oid : Int
  id : Int
  mut hp : Int
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
    last_portal_id: 23,
    last_object_id: 100000,
    mobs: Map::new(),
  }
}

///|
fn init {
  default_server.client_message_handler_map[@net.ClientOpcode::SELECT_CHAR.int_value()] = on_select_char
  default_server.client_message_handler_map[@net.ClientOpcode::CHANGE_MAP.int_value()] = default_server.on_change_map(
    _,
  )
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
  @log.log(log_level, { "message": json }, "send", loc~)
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
  @log.log(log_level, { "message": json }, "send_server_message", loc~)
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
    @log.debug({ "type_code": type_code, "json": json }, "server message")
    guard default_server.server_message_handlers_map.get(type_code)
      is Some(handlers) else {
      continue
    }
    for handler in handlers {
      (handler.1)(json) catch {
        err =>
          @log.error(
            { "error": err.to_string(), "name": handler.0 },
            "Error handling server message",
          )
      }
    }
  }
  while default_server.client_message_queue.pop() is Some((type_code, json)) {
    guard default_server.client_message_handler_map.get(type_code)
      is Some(handler) else {
      @log.debug(
        { "type_code": type_code, "json": json },
        "Missing client message handler",
      )
      return
    }
    handler(json) catch {
      err => abort("Error handling client message: \{err.to_string()}")
    }
  }
}
