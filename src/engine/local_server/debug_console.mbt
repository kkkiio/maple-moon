///|
fn parse_int_arg(args : Array[String], index : Int, default : Int) -> Int {
  guard index >= 0 && index < args.length() else { return default }
  @string.parse_int(args[index]) catch {
    _ => default
  }
}

///|
fn LocalServer::send_temp_set_field(
  self : LocalServer,
  map_id : Int,
  portal_id : Int,
) -> Unit {
  let current_items = Array::new()
  self.append_inventory_entries(current_items)
  let set_field_message = SetFieldMessage::SetField(
    stats=StatsEntry::{
      name: "__temp_console__",
      female: false,
      stats: default_player_stats(),
      i64stats: Default::default(),
      map_id,
      portal_id,
    },
    inventory_entry=InventoryEntry::{
      meso: self.player_meso,
      slot_maxs: @res.EnumMap(self.slot_max_by_tab),
      items: current_items,
    },
    skills=[],
    cooldowns=Default::default(),
    quests=self.build_player_quest_log_info(),
  )
  self.last_map_id = map_id
  self.last_portal_id = portal_id
  self.send_server_message(set_field_message)
  self.spawn_mobs_for_map(map_id)
}

///|
fn LocalServer::register_debug_console_commands(self : LocalServer) -> Unit {
  @console.register_command("temp_set_field_enter", fn(args) {
    let map_id = parse_int_arg(args, 0, 103000000)
    let portal_id = parse_int_arg(args, 1, 0)
    self.send_temp_set_field(map_id, portal_id)
    {
      "ok": true,
      "code": "SET_FIELD_SENT",
      "map_id": map_id,
      "portal_id": portal_id,
    }
  })
}
