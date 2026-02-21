///|
fn parse_set_field(recv : @net.InPacket) -> SetFieldMessage raise {
  recv.read_int() |> ignore // channel
  let mode1 = recv.read_byte()
  let mode2 = recv.read_byte()
  if mode1 == 0 && mode2 == 0 {
    recv.skip(3)
    let mapid = recv.read_int()
    let portalid = recv.read_byte()
    return SetFieldMessage::ChangeMap(map_id=mapid, portal_id=portalid)
  } else {
    recv.skip(23)
    recv.read_int() |> ignore // cid
    // update with stats that was loaded on server side after character
    // selection. hp, mp, maxhp, maxmp, mapid...
    let stats = parse_stats(recv)
    recv.read_byte() |> ignore // 'buddycap'
    if recv.read_bool() {
      recv.read_string() |> ignore // 'linkedname'
    }
    let inventory = parse_inventory(recv)
    let skills = parse_skillbook(recv)
    let cooldowns = @combat_impl.parse_cooldowns(recv)
    let quests = @quest.parse_player_quest_info(recv)
    return SetFieldMessage::SetField(
      stats~,
      inventory_entry=inventory,
      skills~,
      cooldowns~,
      quests~,
    )
  }
}

///|
/// handle_set_field handles packets which contains all character information on first login
/// or warps the player to a different map
fn handle_set_field(
  transition : (Int, Int) -> Unit,
  login_module : Module,
  quest_module : @quest.Module,
  set_player_stage : (
    @character.CharEntry,
    Map[Int, Int],
    (@player.Player) -> Unit raise,
  ) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit,
  message : SetFieldMessage,
) -> Unit {
  // @config.constants.set_viewwidth(Setting::get(configWidth).load())
  // @config.constants.set_viewheight(Setting::get(configHeight).load())
  match message {
    SetFieldMessage::ChangeMap(map_id=mapid, portal_id=portalid) =>
      transition(mapid, portalid)
    SetFieldMessage::SetField(
      stats~,
      inventory_entry~,
      skills~,
      cooldowns~,
      quests~
    ) => {
      let playerentry = login_module.get_selected_char().unwrap() // TODO: handle None
      let playerentry = { ..playerentry, stats, }
      quest_module.handle_player_quest_info(quests)
      set_field(
        login_module.network,
        transition,
        playerentry,
        set_player_stage,
        inventory,
        setup_game_ui,
        inventory_entry,
        skills,
        cooldowns.0,
      )
    }
  }
}

///|
fn set_field(
  net : @net.Network,
  transition : (Int, Int) -> Unit,
  playerentry : @character.CharEntry,
  set_player_stage : (
    @character.CharEntry,
    Map[Int, Int],
    (@player.Player) -> Unit raise,
  ) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit,
  inventory_entry : InventoryEntry,
  skills : Array[SkillEntry],
  cooldowns : Map[Int, Int],
) -> Unit {
  inventory.set_meso(inventory_entry.meso)
  for kind, slotmax in inventory_entry.slot_maxs.0 {
    inventory.set_slotmax(kind, slotmax)
  }

  // parse_minigame(recv);
  // parse_ring1(recv);
  // parse_ring2(recv);
  // parse_ring3(recv);
  // parse_teleportrock(recv, player.get_teleport_rock());
  // parse_monsterbook(recv, player.get_monsterbook());
  // parse_nyinfo(recv);
  // parse_areainfo(recv);
  set_player_stage(playerentry, cooldowns, fn(player) {
    for item in inventory_entry.items {
      @inventory.handle_item(inventory, item)
    }
    register_local_inventory_sync_handler_once(inventory)
    @inventory_ui.bind_inventory(inventory)
    handle_skills(player.get_skills(), skills)
    player.recalc_stats(true)
    net.send_message(PlayerUpdatePacket(()))
    let portalid = player.get_stats().get_portal()
    let mapid = player.get_stats().get_map_id()
    transition(mapid, portalid)

    // Sound(Sound::Name::GAME_START).play();

    setup_game_ui(player)
  })
}

///|
let local_inventory_sync_registered : Ref[Bool] = Ref::new(false)

///|
fn register_local_inventory_sync_handler_once(
  inventory : @inventory.Inventory,
) -> Unit {
  if local_inventory_sync_registered.val {
    return
  }
  local_inventory_sync_registered.val = true
  @game_server.add_server_message_handler(
    "change_stats_meso",
    @net.Opcode::CHANGE_STATS.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @maple_protocol.ChangeStatsMesoMessage = @json.from_json(
        json,
      )
      inventory.set_meso(message.meso)
    },
  )
  @game_server.add_server_message_handler(
    "show_status_info_meso_gain",
    @net.Opcode::SHOW_STATUS_INFO.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @maple_protocol.ShowStatusMesoGainMessage = @json.from_json(
        json,
      )
      @log.info("local show status meso gain", data={ "gain": message.gain })
    },
  )
  @game_server.add_server_message_handler(
    "modify_inventory_local",
    @net.Opcode::MODIFY_INVENTORY.int_value(),
    fn(json : Json) -> Unit raise {
      let message : @maple_protocol.ModifyInventoryItemMessage = @json.from_json(
        json,
      )
      @inventory.handle_item(inventory, message.item)
    },
  )
}

///|
/// Finished updating player stats
priv struct PlayerUpdatePacket(Unit) derive(Show)

///|
impl @net.OutMessage for PlayerUpdatePacket with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::PLAYER_UPDATE)
}

///|
using @maple_protocol {type InventoryType}

///|
fn parse_inventory(recv : @net.InPacket) -> InventoryEntry raise {
  let meso = recv.read_int()
  let slotmax = Map::new()
  let items = Array::new()
  slotmax.set(InventoryType::EQUIP, recv.read_ubyte())
  slotmax.set(InventoryType::USE, recv.read_ubyte())
  slotmax.set(InventoryType::SETUP, recv.read_ubyte())
  slotmax.set(InventoryType::ETC, recv.read_ubyte())
  slotmax.set(InventoryType::CASH, recv.read_ubyte())
  recv.skip(8)
  for i in 0..<3 {
    let inv = if i == 0 {
      InventoryType::EQUIPPED
    } else {
      InventoryType::EQUIP
    }
    let mut pos = recv.read_short()
    while pos != 0 {
      let slot = if i == 1 { -pos } else { pos }
      items.push(@inventory.parse_item(recv, inv, slot))
      pos = recv.read_short()
    }
  }
  recv.skip(2)
  let toparse = [
    InventoryType::USE,
    InventoryType::SETUP,
    InventoryType::ETC,
    InventoryType::CASH,
  ]
  for inv in toparse {
    let mut pos = recv.read_byte()
    while pos != 0 {
      items.push(@inventory.parse_item(recv, inv, pos))
      pos = recv.read_byte()
    }
  }
  { meso, slot_maxs: slotmax, items }
}

///|
fn parse_skillbook(recv : @net.InPacket) -> Array[SkillEntry] raise {
  let size = recv.read_short()
  let entries = Array::new()
  for i in 0..<size {
    let skill_id = recv.read_int()
    let level = recv.read_int()
    let expiration = recv.read_long()
    let fourthtjob = skill_id % 100000 / 10000 == 2
    let masterlevel = if fourthtjob { recv.read_int() } else { 0 }
    entries.push(SkillEntry::{ skill_id, level, masterlevel, expiration })
  }
  entries
}

///|
fn handle_skills(
  skills : &@legacy_types.SkillBook,
  entries : Array[SkillEntry],
) -> Unit {
  for entry in entries {
    skills.set_skill(
      entry.skill_id,
      entry.level,
      entry.masterlevel,
      entry.expiration.to_int(),
    )
  }
}

///|
using @maple_protocol {
  type ChangeStatsMesoMessage,
  type InventoryEntry,
  type ModifyInventoryItemMessage,
  type ShowStatusMesoGainMessage,
  type SkillEntry,
}
