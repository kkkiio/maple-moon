///|
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
    let portal_id = 0 // TODO: get portal id by change_map_message.target_p
    let set_field_message : SetFieldMessage = SetFieldMessage::ChangeMap(
      map_id=change_map_message.target_id,
      portal_id~,
    )
    let set_field_json = set_field_message.to_json()
    default_server.server_message_queue.push(
      (@net.Opcode::SET_FIELD.int_value(), set_field_json),
    )
  }
}
