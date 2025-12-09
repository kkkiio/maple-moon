///|
fn on_select_char(json : Json) -> Unit raise {
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
