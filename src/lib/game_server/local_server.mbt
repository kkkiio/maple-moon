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
  last_map_id : Int
  last_portal_id : Int
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
  }
}

///|
using @maple_protocol {
  trait ClientMessage,
  type ChangeMapMessage,
  type SetFieldMessage,
  type SelectCharMessage,
  type StatsEntry,
  type InventoryEntry,
  type PlayerQuestLogInfo,
}

///|
fn init {
  default_server.client_message_handler_map[@net.ClientOpcode::SELECT_CHAR.int_value()] = fn(
    json,
  ) {
    let _ : SelectCharMessage = @json.from_json(json)
    // hardcode character for mvp
    let set_field_message = SetFieldMessage::SetField(
      stats=StatsEntry::{
        name: "kkkiio",
        female: false,
        stats: @resource.EnumMap::default(),
        i64stats: @resource.EnumMap::default(),
        map_id: default_server.last_map_id,
        portal_id: default_server.last_portal_id,
      },
      inventory_entry=InventoryEntry::default(),
      skills=[],
      cooldowns=@resource.EnumMap::default(),
      quests=PlayerQuestLogInfo::default(),
    )
    let set_field_json = set_field_message.to_json()
    default_server.server_message_queue.push(
      (@net.Opcode::SET_FIELD.int_value(), set_field_json),
    )
  }
  default_server.client_message_handler_map[@net.ClientOpcode::CHANGE_MAP.int_value()] = fn(
    json,
  ) {
    let change_map_message : ChangeMapMessage = @json.from_json(json)
    @io_service.execute_background(async fn() {
      guard get_portal_id_by_map_id_and_portal_name(
          change_map_message.target_id,
          change_map_message.target_p,
        )
        is Some(portal_id) else {
        @log.error(
          {
            "map_id": change_map_message.target_id,
            "portal_name": change_map_message.target_p,
          },
          "portal not found",
        )
        return
      }
      let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
        map_id=change_map_message.target_id,
        portal_id~,
      )
      let set_field_json = set_field_message.to_json()
      default_server.server_message_queue.push(
        (@net.Opcode::SET_FIELD.int_value(), set_field_json),
      )
    })
  }
}

///|
async fn get_portal_id_by_map_id_and_portal_name(
  map_id : Int,
  portal_name : String,
) -> Int? {
  let loader = get_mapx_loader()
  let prefix = (map_id / 100000000).to_string()
  let strid = @utils.stoi_left_pad0(map_id, 9)
  let path = ["Map\{prefix}", "\{strid}.img"]
  let node = loader.load_res_async(path)
  let portals = node["portal"]
  for portal in portals.iter() {
    if portal["pn"].get_string() == portal_name {
      let id_str = portal.name()
      return Some(@strconv.parse_int(id_str))
    }
  }
  None
}

///|
using @resource {get_mapx_loader}
