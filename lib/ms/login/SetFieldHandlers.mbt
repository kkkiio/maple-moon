///| handle_set_field handles packets which contains all character information on first login
/// or warps the player to a different map
pub fn handle_set_field(
  transition : (Int, Int) -> Unit,
  login_module : Module,
  set_player_stage : (@character.CharEntry, (@player.Player) -> Unit!) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit,
  recv : @net.InPacket
) -> Unit! {
  // @constants.constants.set_viewwidth(Setting::get(configWidth).load())
  // @constants.constants.set_viewheight(Setting::get(configHeight).load())
  recv.read_int!() |> ignore // channel
  let mode1 = recv.read_byte!()
  let mode2 = recv.read_byte!()
  if mode1 == 0 && mode2 == 0 {
    change_map!(transition, recv)
  } else {
    set_field!(
      transition,
      recv,
      login_module.get_selected_char().unwrap(),
      set_player_stage,
      inventory,
      setup_game_ui,
    )
  }
}

///|
fn change_map(transition : (Int, Int) -> Unit, recv : @net.InPacket) -> Unit! {
  recv.skip!(3)
  let mapid = recv.read_int!()
  let portalid = recv.read_byte!()
  transition(mapid, portalid)
}

///|
fn set_field(
  transition : (Int, Int) -> Unit,
  recv : @net.InPacket,
  playerentry : @character.CharEntry,
  set_player_stage : (@character.CharEntry, (@player.Player) -> Unit!) -> Unit,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit
) -> Unit! {
  recv.skip!(23)
  recv.read_int!() |> ignore // cid

  // update with stats that was loaded on server side after character
  // selection. hp, mp, maxhp, maxmp, mapid...
  let stats = parse_stats!(recv)
  let playerentry = { ..playerentry, stats, }
  set_player_stage(
    playerentry,
    fn(player) {
      recv.read_byte!() |> ignore // 'buddycap'
      if recv.read_bool!() {
        recv.read_string!() |> ignore // 'linkedname'
      }
      parse_inventory!(recv, inventory)
      parse_skillbook!(recv, player.get_skills())
      // parse_cooldowns(recv, player);
      // parse_questlog(recv, player.get_quests());
      // parse_minigame(recv);
      // parse_ring1(recv);
      // parse_ring2(recv);
      // parse_ring3(recv);
      // parse_teleportrock(recv, player.get_teleport_rock());
      // parse_monsterbook(recv, player.get_monsterbook());
      // parse_nyinfo(recv);
      // parse_areainfo(recv);

      player.recalc_stats(true)
      new_player_update_packet().dispatch()
      let portalid = player.get_stats().get_portal()
      let mapid = player.get_stats().get_map_id()
      transition(mapid, portalid)

      // Sound(Sound::Name::GAME_START).play();

      setup_game_ui(player)
    },
  )
}

///| Finished updating player stats
fn new_player_update_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_UPDATE)
}

///|
fn parse_inventory(
  recv : @net.InPacket,
  invent : @inventory.Inventory
) -> Unit! {
  invent.set_meso(recv.read_int!())
  invent.set_slotmax(@inventory.TypeId::EQUIP, recv.read_ubyte!())
  invent.set_slotmax(@inventory.TypeId::USE, recv.read_ubyte!())
  invent.set_slotmax(@inventory.TypeId::SETUP, recv.read_ubyte!())
  invent.set_slotmax(@inventory.TypeId::ETC, recv.read_ubyte!())
  invent.set_slotmax(@inventory.TypeId::CASH, recv.read_ubyte!())
  recv.skip!(8)
  for i in 0..<3 {
    let inv = if i == 0 {
      @inventory.TypeId::EQUIPPED
    } else {
      @inventory.TypeId::EQUIP
    }
    let mut pos = recv.read_short!()
    while pos != 0 {
      let slot = if i == 1 { -pos } else { pos }
      @inventory.parse_item!(recv, inv, slot, invent)
      pos = recv.read_short!()
    }
  }
  recv.skip!(2)
  let toparse = [
    @inventory.TypeId::USE,
    @inventory.TypeId::SETUP,
    @inventory.TypeId::ETC,
    @inventory.TypeId::CASH,
  ]
  for inv in toparse {
    let mut pos = recv.read_byte!()
    while pos != 0 {
      @inventory.parse_item!(recv, inv, pos, invent)
      pos = recv.read_byte!()
    }
  }
}

///|
fn parse_skillbook(
  recv : @net.InPacket,
  skills : @character.SkillBook
) -> Unit! {
  let size = recv.read_short!()
  for i in 0..<size {
    let skill_id = recv.read_int!()
    let level = recv.read_int!()
    let expiration = recv.read_long!()
    let fourthtjob = skill_id % 100000 / 10000 == 2
    let masterlevel = if fourthtjob { recv.read_int!() } else { 0 }
    skills.set_skill(skill_id, level, masterlevel, expiration.to_int())
  }
}
