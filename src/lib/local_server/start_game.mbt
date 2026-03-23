///|
fn default_player_stats() -> @resource.EnumMap[@maple_stat.Id, Int] {
  @resource.EnumMap(
    Map::from_array([
      (@maple_stat.Id::LEVEL, 50),
      (@maple_stat.Id::JOB, 0),
      (@maple_stat.Id::STR, 12),
      (@maple_stat.Id::DEX, 120),
      (@maple_stat.Id::INT, 4),
      (@maple_stat.Id::LUK, 4),
      (@maple_stat.Id::MAXHP, 2000),
      (@maple_stat.Id::HP, 2000),
      (@maple_stat.Id::MAXMP, 500),
      (@maple_stat.Id::MP, 500),
      (@maple_stat.Id::AP, 0),
      (@maple_stat.Id::SP, 0),
      (@maple_stat.Id::FAME, 0),
    ]),
  )
}

///|
fn LocalServer::on_select_char(self : LocalServer, json : Json) -> Unit raise {
  let default_server = self
  let select_char_message : SelectCharMessage = @json.from_json(json)
  default_server.current_character_id = select_char_message.character_id
  guard default_server.find_character_entry(default_server.current_character_id)
    is Some(entry) else {
    @log.fatal("Player character metadata missing! Aborting.", data={
      "character_id": default_server.current_character_id.to_string(),
    })
    return
  }
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
        name: entry.name,
        female: entry.look.female,
        stats: default_player_stats(),
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
      quests=default_server.build_player_quest_log_info(),
    )
    let set_field_json = set_field_message.to_json()
    default_server.server_message_queue.push(
      (@server_proto.Opcode::SET_FIELD.int_value(), set_field_json),
    )
    default_server.spawn_mobs_for_map(default_server.last_map_id)
  })
}
