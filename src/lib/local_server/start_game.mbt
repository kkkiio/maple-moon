///|
fn LocalServer::on_select_char(self : LocalServer, json : Json) -> Unit raise {
  let default_server = self
  let select_char_message : SelectCharMessage = @json.from_json(json)
  default_server.current_character_id = select_char_message.character_id
  @io_service.execute_background(async fn() {
    default_server.load_character(default_server.current_character_id)

    // hardcode character for mvp
    let stats : @resource.EnumMap[@maple_stat.Id, Int] = @resource.EnumMap::default()
    stats.0.set(@maple_stat.Id::LEVEL, 10)
    stats.0.set(@maple_stat.Id::STR, 50)
    stats.0.set(@maple_stat.Id::DEX, 50)
    stats.0.set(@maple_stat.Id::MAXHP, 500)
    stats.0.set(@maple_stat.Id::HP, 500)
    stats.0.set(@maple_stat.Id::MAXMP, 200)
    stats.0.set(@maple_stat.Id::MP, 200)
    let items = Array::new()
    let weapon_stats : @resource.EnumMap[@maple_stat.EquipStatId, Int] = @resource.EnumMap::default()
    weapon_stats.0.set(@maple_stat.EquipStatId::WATK, 10)
    items.push(
      @server_proto.InventoryItemEntry::Equip(
        invtype=InventoryType::EQUIPPED,
        slot=-11,
        id=1302000, // beginner sword
        cash=false,
        expire=0,
        slots=7,
        level=0,
        stats=weapon_stats,
        owner="",
        flag=0,
        itemlevel=0,
        itemexp=0,
        vicious=0,
      ),
    )
    let empty_equip_stats : @resource.EnumMap[@maple_stat.EquipStatId, Int] = @resource.EnumMap::default()
    items.push(
      @server_proto.InventoryItemEntry::Equip(
        invtype=InventoryType::EQUIPPED,
        slot=-5,
        id=1040002, // top
        cash=false,
        expire=0,
        slots=7,
        level=0,
        stats=empty_equip_stats,
        owner="",
        flag=0,
        itemlevel=0,
        itemexp=0,
        vicious=0,
      ),
    )
    items.push(
      @server_proto.InventoryItemEntry::Equip(
        invtype=InventoryType::EQUIPPED,
        slot=-6,
        id=1060002, // bottom
        cash=false,
        expire=0,
        slots=7,
        level=0,
        stats=empty_equip_stats,
        owner="",
        flag=0,
        itemlevel=0,
        itemexp=0,
        vicious=0,
      ),
    )
    items.push(
      @server_proto.InventoryItemEntry::Equip(
        invtype=InventoryType::EQUIPPED,
        slot=-7,
        id=1072005, // shoes
        cash=false,
        expire=0,
        slots=7,
        level=0,
        stats=empty_equip_stats,
        owner="",
        flag=0,
        itemlevel=0,
        itemexp=0,
        vicious=0,
      ),
    )
    default_server.append_inventory_entries(items)
    let set_field_message = SetFieldMessage::SetField(
      stats=StatsEntry::{
        name: "kkkiio",
        female: false,
        stats,
        i64stats: @resource.EnumMap::default(),
        map_id: default_server.last_map_id,
        portal_id: default_server.last_portal_id,
      },
      inventory_entry=InventoryEntry::{
        meso: default_server.player_meso,
        slot_maxs: @resource.EnumMap(default_server.slot_max_by_tab),
        items,
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
