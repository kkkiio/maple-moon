///|
fn parse_set_field(recv : @net.InPacket) -> SetFieldMessage raise {
  recv.read_int() |> ignore // channel
  let mode1 = recv.read_byte()
  let mode2 = recv.read_byte()
  if mode1 == 0 && mode2 == 0 {
    recv.skip(3)
    let mapid = recv.read_int()
    let portalid = recv.read_byte()
    return SetFieldMessage::ChangeMap(mapid~, portalid~)
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
    let cooldowns = @combat_impl2.parse_cooldowns(recv)
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
priv enum SetFieldMessage {
  ChangeMap(mapid~ : Int, portalid~ : Int)
  SetField(
    stats~ : @char_stats.StatsEntry,
    inventory_entry~ : InventoryEntry,
    skills~ : Array[SkillEntry],
    cooldowns~ : Map[Int, Int],
    quests~ : @quest.PlayerQuestLogInfo
  )
} derive(Show)

///| handle_set_field handles packets which contains all character information on first login
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
  message : SetFieldMessage
) -> Unit {
  // @config.constants.set_viewwidth(Setting::get(configWidth).load())
  // @config.constants.set_viewheight(Setting::get(configHeight).load())
  match message {
    SetFieldMessage::ChangeMap(mapid~, portalid~) => transition(mapid, portalid)
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
        cooldowns,
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
  cooldowns : Map[Int, Int]
) -> Unit {
  inventory.set_meso(inventory_entry.meso)
  for kind, slotmax in inventory_entry.slotmax {
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

///| Finished updating player stats
priv type PlayerUpdatePacket Unit derive(Show)

///|
impl @net.OutMessage for PlayerUpdatePacket with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::PLAYER_UPDATE)
}

///|
priv struct InventoryEntry {
  meso : Int
  slotmax : Map[@inventory.TypeId, Int]
  items : Array[@inventory.InventoryItemEntry]
} derive(Show)

///|
fn parse_inventory(recv : @net.InPacket) -> InventoryEntry raise {
  let meso = recv.read_int()
  let slotmax = Map::new()
  let items = Array::new()
  slotmax.set(@inventory.TypeId::EQUIP, recv.read_ubyte())
  slotmax.set(@inventory.TypeId::USE, recv.read_ubyte())
  slotmax.set(@inventory.TypeId::SETUP, recv.read_ubyte())
  slotmax.set(@inventory.TypeId::ETC, recv.read_ubyte())
  slotmax.set(@inventory.TypeId::CASH, recv.read_ubyte())
  recv.skip(8)
  for i in 0..<3 {
    let inv = if i == 0 {
      @inventory.TypeId::EQUIPPED
    } else {
      @inventory.TypeId::EQUIP
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
    @inventory.TypeId::USE,
    @inventory.TypeId::SETUP,
    @inventory.TypeId::ETC,
    @inventory.TypeId::CASH,
  ]
  for inv in toparse {
    let mut pos = recv.read_byte()
    while pos != 0 {
      items.push(@inventory.parse_item(recv, inv, pos))
      pos = recv.read_byte()
    }
  }
  { meso, slotmax, items }
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
    entries.push({ skill_id, level, masterlevel, expiration })
  }
  entries
}

///|
fn handle_skills(
  skills : &@player.SkillBook,
  entries : Array[SkillEntry]
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
priv struct SkillEntry {
  skill_id : Int
  level : Int
  masterlevel : Int
  expiration : Int64
} derive(Show)
