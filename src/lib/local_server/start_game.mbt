///|
fn LocalServer::on_select_char(self : LocalServer, json : Json) -> Unit raise {
  let default_server = self
  let select_char_message : SelectCharMessage = @json.from_json(json)
  default_server.current_character_id = select_char_message.character_id
  @io_service.execute_background(async fn() {
    let has_save_data = default_server.load_character(
      default_server.current_character_id,
    )

    if not(has_save_data) {
      @log.fatal("Player character save data missing! Aborting.", data={
        "character_id": default_server.current_character_id.to_string(),
      })
      return
    }

    let current_items = Array::new()
    default_server.append_inventory_entries(current_items)

    let set_field_message = SetFieldMessage::SetField(
      stats=StatsEntry::{
        name: "kkkiio",
        female: false,
        stats: @resource.EnumMap::default(), // FIXME: pull actual player stats from db down the line
        i64stats: @resource.EnumMap::default(),
        map_id: default_server.last_map_id,
        portal_id: default_server.last_portal_id,
      },
      inventory_entry=InventoryEntry::{
        meso: default_server.player_meso,
        slot_maxs: @resource.EnumMap(default_server.slot_max_by_tab),
        items: current_items,
      },
      skills=[],
      cooldowns=@resource.EnumMap::default(),
      quests=PlayerQuestLogInfo::default(),
    )
    let set_field_json = set_field_message.to_json()
    default_server.server_message_queue.push(
      (@net.Opcode::SET_FIELD.int_value(), set_field_json),
    )
    default_server.spawn_mobs_for_map(default_server.last_map_id)
  })
}
