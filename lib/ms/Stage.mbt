enum StageState {
  INACTIVE
  TRANSITION
  ACTIVE
} derive(Eq, Show)

pub struct Stage {
  camera : Camera
  mut physics : Physics
  mut player : @player.Player?
  mut state : StageState
  mut map_id : Int
  mut map_info : @map.MapInfo
  mut tiles_objs : MapTilesObjs
  mut backgrounds : MapBackgrounds?
  mut portals : MapPortals
  npcs : MapNpcs
  mobs : @monster.MapMobs
  mut combat : Combat?
  mut start : TimePoint
}

pub fn Stage::new(mobs : @monster.MapMobs) -> Stage {
  {
    camera: Camera::new(),
    player: None,
    physics: Physics::new(),
    state: StageState::INACTIVE,
    backgrounds: None,
    tiles_objs: MapTilesObjs::default(),
    map_id: 10000,
    map_info: @map.MapInfo::new(),
    portals: MapPortals::default(),
    npcs: MapNpcs::new(),
    combat: None,
    mobs,
    start: TimePoint::default(),
  }
}

pub fn Stage::get() -> Stage {
  stage.must_get()
}

pub fn clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
  // self.chars.clear()
  self.npcs.clear()
  self.mobs.clear()
  // self.drops.clear()
  // self.reactors.clear()
}

let stage : @utils.Singleton[Stage] = @utils.Singleton::new()

pub fn load(self : Stage, mapid : Int, portalid : Int) -> Unit {
  match self.state {
    StageState::INACTIVE => {
      self.load_map(mapid)
      self.respawn(portalid)
    }
    StageState::TRANSITION => self.respawn(portalid)
    _ => ()
  }
  self.state = StageState::ACTIVE
}

pub fn load_player(
  self : Stage,
  entry : @login.CharEntry,
  wid : Int,
  channel_id : Int
) -> @player.Player! {
  let player = @player.Player::from_entry!(entry, wid, channel_id)
  self.player = Some(player)
  self.combat = Some(Combat::new(player, self.mobs))
  self.start = now_micro() |> TimePoint::from_micro

  // CharStats stats = self.player.get_stats();
  // level_before_ = stats.get_stat(@MapleStat.Id::LEVEL);
  // exp_before_ = stats.get_exp();
  player
}

pub fn get_player(self : Stage) -> @player.Player? {
  self.player
}

pub fn get_npcs(self : Stage) -> MapNpcs {
  self.npcs
}

fn load_map(self : Stage, mapid : Int) -> Unit {
  self.map_id = mapid
  let strid = @string_format.extend_id(mapid, 9)
  let prefix = (mapid / 100000000).to_string()
  let src = if mapid == -1 {
    ui_loader().load_res(["CashShopPreview.img"])
  } else {
    map_loader().load_res(["Map", "Map\{prefix}", "\{strid}.img"])
  }
  self.tiles_objs = MapTilesObjs::from_resource(src)
  self.backgrounds = Some(MapBackgrounds::new(src["back"]))
  self.physics = Physics::from_resource(src["foothold"])
  self.map_info = @map.MapInfo::from_resource(
    src,
    self.physics.get_fht().get_walls(),
    self.physics.get_fht().get_borders(),
  )
  self.portals = MapPortals::from_resource(src["portal"], mapid)
}

pub fn respawn(self : Stage, portalid : Int) -> Unit {
  // Music(self.map_info.get_bgm()).play();
  let spawnpoint = self.portals.get_portal_by_id(portalid)
  let startpos = self.physics.get_y_below(spawnpoint)
  self.player.unwrap().respawn(startpos, self.map_info.is_underwater())
  self.camera.set_position(startpos)
  self.camera.set_view(self.map_info.get_walls(), self.map_info.get_borders())
}

pub fn draw(self : Stage, alpha : Double) -> Unit {
  if self.state != StageState::ACTIVE {
    return
  }
  let viewpos = self.camera.position_interpolated(alpha)
  let viewrpos = self.camera.real_position(alpha)
  let viewx = viewrpos.x
  let viewy = viewrpos.y
  self.backgrounds.unwrap().drawbackgrounds(viewx, viewy, alpha)
  let player = self.player.unwrap()
  @layer.ids.each(
    fn(id) {
      self.tiles_objs.draw(id, viewpos, alpha)
      // reactors_.draw(id, viewx, viewy, alpha);
      self.npcs.draw(id, viewx, viewy, alpha)
      self.mobs.draw(id, viewx, viewy, alpha)
      // chars_.draw(id, viewx, viewy, alpha);
      player.draw(id, viewx, viewy, alpha)
      // drops_.draw(id, viewx, viewy, alpha);
    },
  )
  @layer.ids.each(fn(id) { player.draw(id, viewx, viewy, alpha) })
  self.combat.unwrap().draw(viewx, viewy, alpha)
  self.portals.draw(viewpos, alpha)
  self.backgrounds.unwrap().drawforegrounds(viewx, viewy, alpha)
  //     effect_.draw();
  // 
}

pub fn transfer_player(self : Stage) -> Unit {
  new_player_map_transfer_packet().dispatch()

  // if (@config.global().get_admin()) {
  //     fn_admin_enter_map(AdminEnterMapPacket::Operation::ALERT_ADMINS);
  // }
}

fn update(self : Stage) -> Unit {
  if self.state != StageState::ACTIVE {
    return
  }
  self.combat.unwrap().update()
  self.backgrounds.unwrap().update()
  // effect_.update();
  self.tiles_objs.update()

  // reactors_.update(self.physics);
  self.npcs.update(self.physics)
  self.mobs.update?(self.physics).unwrap()
  // chars_.update(self.physics);
  // drops_.update(self.physics);
  let player = self.player.unwrap()
  player.update(self.physics) |> ignore
  self.portals.update(player.get_position())
  self.camera.update(player.get_position())
  if player.is_invincible() {
    return
  }
  match self.mobs.find_colliding(player.get_phobj().moving_object) {
    Some(oid_id) =>
      match self.mobs.create_attack(oid_id) {
        Some(attack) => {
          let result = player.damage(attack)
          new_take_damage_packet_from_mob(result, TakeDamageFrom::TOUCH).dispatch()
        }
        None => ()
      }
    None => ()
  }
}

fn send_cursor(
  self : Stage,
  pressed : Bool,
  position : Point[Int]
) -> CursorState {
  // auto statusbar = UI::get().get_element<UIStatusBar>();

  // if (statusbar && statusbar->get().is_menu_active()) {
  //     if (pressed) {
  //         statusbar->get().remove_menus();
  //     }

  //     if (statusbar->get().is_in_range(position)) {
  //         return statusbar->get().send_cursor(pressed, position);
  //     }
  // }

  self.npcs.send_cursor(pressed, position, self.camera.position())
}

pub fn send_key(
  self : Stage,
  t : @KeyType.Id,
  action : Int,
  down : Bool
) -> Unit! {
  if self.state != StageState::ACTIVE {
    return
  }
  match self.player {
    Some(player) =>
      match t {
        @KeyType.Id::ACTION => {
          if down {
            match @KeyAction.get_action_by_id?(action).unwrap() {
              @KeyAction.Id::UP => {
                self.check_ladders(player, true)
                self.check_portals()
              }
              @KeyAction.Id::DOWN => self.check_ladders(player, false)
              // @KeyAction.Id::SIT => self.check_seats()
              @KeyAction.Id::ATTACK => self.combat.unwrap().use_move!(0)
              // @KeyAction.Id::PICKUP => self.check_drops()
              _ => ()
            }
          }
          player.send_action(
            @KeyAction.get_action_by_id?(action).unwrap(),
            down,
          )
        }
        @KeyType.Id::SKILL => self.combat.unwrap().use_move!(action)
        // @KeyType.Id::ITEM => self.player.use_item(action)
        // @KeyType.Id::FACE => self.player.set_expression(action)
        _ => ()
      }
    None => ()
  }
}

fn check_portals(self : Stage) -> Unit {
  let player = self.player.unwrap()
  if player.is_attacking() {
    return
  }
  let playerpos = player.get_position()
  let warpinfo = self.portals.find_warp_at(playerpos)
  if warpinfo.intramap {
    let spawnpoint = self.portals.get_portal_by_name(warpinfo.toname)
    let startpos = self.physics.get_y_below(spawnpoint)
    player.respawn(startpos, self.map_info.is_underwater())
  } else if warpinfo.valid {
    new_change_map_packet(false, -1, warpinfo.name, false).dispatch()
    let stats = player.get_stats()
    stats.set_mapid(warpinfo.mapid)
  }

  // Sound(Sound::Name::PORTAL).play();
}

pub fn doubleclick(self : Stage, pos : Point[Int]) -> Unit {
  // TODO
}

fn new_change_map_packet(
  died : Bool,
  targetid : Int,
  targetp : String,
  usewheel : Bool
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CHANGE_MAP)
  ..write_byte(died.to_int().to_byte())
  ..write_int(targetid)
  ..write_string(targetp)
  ..skip(1)
  ..write_short(if usewheel { 1 } else { 0 })
}

struct ChangeStatsHandler {} derive(Default)

fn ChangeStatsHandler::new() -> ChangeStatsHandler {
  ChangeStatsHandler::default()
}

fn handle(self : ChangeStatsHandler, recv : @net.InPacket) -> Unit! {
  recv.read_bool!() |> ignore // 'itemreaction'
  let updatemask = recv.read_int!()
  let recalculate = false
  // @MapleStat.codes.each(
  //   fn(stat_id, stat_mask) {
  //     if (updatemask & stat_mask) != 0 {
  //       recalculate = recalculate || self.handle_stat!(stat_id, recv)
  //     }
  //   },
  // )
  if recalculate {
    Stage::get().get_player().unwrap().recalc_stats!(false)
  }
  UI::get().enable()
}

fn handle_stat(
  self : ChangeStatsHandler,
  stat : @MapleStat.Id,
  recv : @net.InPacket
) -> Bool! {
  let player = Stage::get().get_player().unwrap()
  let mut recalculate = false
  match stat {
    @MapleStat.Id::SKIN => player.change_look(stat, recv.read_short!())
    @MapleStat.Id::FACE | @MapleStat.Id::HAIR =>
      player.change_look(stat, recv.read_int!())
    // @MapleStat.Id::LEVEL => player.change_level(recv.read_ubyte())
    // @MapleStat.Id::JOB => player.change_job(recv.read_ushort())
    @MapleStat.Id::HP => {
      let current_hp = recv.read_short!()
      player.get_stats().set_stat(stat, current_hp)
      recalculate = true
      if current_hp <= 0 {
        player.set_state(@character.CharState::DIED)
        let died = true
        let targetid = 0
        new_change_map_packet(died, targetid, "sp", false).dispatch()
      }
    }
    // @MapleStat.Id::EXP => player.get_stats().set_exp(recv.read_int!())
    // @MapleStat.Id::MESO => player.get_inventory().set_meso(recv.read_int!())
    _ => {
      player.get_stats().set_stat(stat, recv.read_short!())
      recalculate = true
    }
  }

  // bool update_statsinfo = need_statsinfo_update(stat);

  // if (update_statsinfo && !recalculate) {
  //     if (auto statsinfo = UI::get().get_element<UIStatsInfo>()) {
  //         statsinfo->get().update_stat(stat);
  //     }
  // }

  // bool update_skillbook = need_skillbook_update(stat);

  // if (update_skillbook) {
  //     int16_t value = player.get_stats().get_stat(stat);

  //     if (auto skillbook = UI::get().get_element<UISkillBook>()) {
  //         skillbook->get().update_stat(stat, value);
  //     }
  // }

  recalculate
}

pub fn new_player_map_transfer_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_MAP_TRANSFER)
}

fn check_ladders(self : Stage, player : @player.Player, up : Bool) -> Unit {
  if player.is_climbing() || player.is_attacking() {
    return
  }
  let ladder = self.map_info.find_ladder(player.get_position(), up)
  player.set_ladder(ladder)
}

pub fn get_mobs(self : Stage) -> @monster.MapMobs {
  self.mobs
}

/// Tells the server that the player took damage.
enum TakeDamageFrom {
  TOUCH
}

fn int_value(self : TakeDamageFrom) -> Int {
  match self {
    TakeDamageFrom::TOUCH => -1
  }
}

fn new_take_damage_packet(
  from : TakeDamageFrom,
  element : Int,
  damage : Int,
  mobid : Int,
  oid : Int,
  direction : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::TAKE_DAMAGE)
  ..write_time()
  ..write_byte(from.int_value().to_byte())
  ..write_byte(element.to_byte())
  ..write_int(damage)
  ..write_int(mobid)
  ..write_int(oid)
  ..write_byte(direction.to_byte())
}

/// From mob attack result.
fn new_take_damage_packet_from_mob(
  result : @combat.MobAttackResult,
  from : TakeDamageFrom
) -> @net.OutPacket {
  new_take_damage_packet(
    from,
    0,
    result.damage,
    result.mobid,
    result.oid,
    result.direction,
  )
}
