// Handler for a packet which contains all character information on first login
// or warps the player to a different map
struct SetFieldHandler {
  login_module : @login.Module
  timer : Timer
}

pub fn SetFieldHandler::new(
  login_module : @login.Module,
  timer : Timer
) -> SetFieldHandler {
  { login_module, timer }
}

pub fn transition(self : SetFieldHandler, mapid : Int, portalid : Int) -> Unit {
  // GraphicsGL::get().lock()
  Stage::get().clear()
  self.timer.start()
  @graphics.GraphicsGL::get().clear()
  Stage::get().load(mapid, portalid)
  UI::get().enable()
  self.timer.start()
  // GraphicsGL::get().unlock()
  transfer_player()
}

pub fn handle(self : SetFieldHandler, recv : @net.InPacket) -> Unit! {
  // @constants.constants.set_viewwidth(Setting::get(configWidth).load())
  // @constants.constants.set_viewheight(Setting::get(configHeight).load())
  recv.read_int!() |> ignore // channel
  let mode1 = recv.read_byte!()
  let mode2 = recv.read_byte!()
  if mode1 == 0 && mode2 == 0 {
    self.change_map!(recv)
  } else {
    self.set_field!(recv, self.login_module.get_selected_char().unwrap())
  }
}

fn change_map(self : SetFieldHandler, recv : @net.InPacket) -> Unit! {
  recv.skip!(3)
  let mapid = recv.read_int!()
  let portalid = recv.read_byte!()
  self.transition(mapid, portalid)
}

fn set_field(
  self : SetFieldHandler,
  recv : @net.InPacket,
  playerentry : @login.CharEntry
) -> Unit! {
  recv.skip!(23)
  recv.read_int!() |> ignore // cid

  // update with stats that was loaded on server side after character
  // selection. hp, mp, maxhp, maxmp, mapid...
  let stats = @login.parse_stats!(recv)
  let playerentry = { ..playerentry, stats, }
  let player = Stage::get().load_player!(playerentry)
  recv.read_byte!() |> ignore // 'buddycap'
  if recv.read_bool!() {
    recv.read_string!() |> ignore // 'linkedname'
  }
  parse_inventory!(recv, Stage::get().get_inventory())
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
  let portalid = player.get_stats().portal
  let mapid = player.get_stats().map_id
  self.transition(mapid, portalid)

  // Sound(Sound::Name::GAME_START).play();

  UI::get().change_state(UiState::GAME)
  let stats = player.get_stats()
  let stats_bar = @player.UIStatusBar::new(stats)
  UI::get().set_element(false, stats_bar)
}

/// Finished updating player stats
fn new_player_update_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_UPDATE)
}

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
