// app/src/main/cpp/src/Gameplay/Stage.h
// app/src/main/cpp/src/Gameplay/Stage.cpp

enum StageState {
  INACTIVE
  TRANSITION
  ACTIVE
} derive(Eq, Show)

pub struct Stage {
  camera : Camera
  mut physics : Physics
  mut player : Player
  priv mut playable : Playable?
  mut state : StageState
  mut backgrounds : MapBackgrounds?
  mut tiles_objs : MapTilesObjs
  mut map_id : Int
  mut map_info : MapInfo
  mut portals : MapPortals
  mut start : TimePoint
}

pub fn Stage::default() -> Stage {
  {
    camera: Camera::new(),
    player: Player::default(),
    playable: None,
    physics: Physics::new(),
    state: StageState::INACTIVE,
    backgrounds: None,
    tiles_objs: MapTilesObjs::default(),
    map_id: 10000,
    map_info: MapInfo::new(),
    portals: MapPortals::default(),
    start: TimePoint::default(),
  }
}

pub fn Stage::get() -> Stage {
  stage
}

pub fn clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
}

let stage : Stage = Stage::default()

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
  entry : CharEntry,
  wid : Int,
  channel_id : Int
) -> Unit {
  self.player = Player::from_entry(entry, wid, channel_id)
  self.playable = Some(self.player)
  self.start = now_micro() |> TimePoint::from_micro

  // CharStats stats = self.player.get_stats();
  // level_before_ = stats.get_stat(@MapleStat.Id::LEVEL);
  // exp_before_ = stats.get_exp();
}

pub fn get_player(self : Stage) -> Player {
  self.player
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
  self.map_info = MapInfo::from_resource(
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
  self.player.respawn(startpos, self.map_info.is_underwater())
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
  @Layer.ids.each(
    fn(id) {
      self.tiles_objs.draw(id, viewpos, alpha)
      // reactors_.draw(id, viewx, viewy, alpha);
      // npcs_.draw(id, viewx, viewy, alpha);
      // mobs_.draw(id, viewx, viewy, alpha);
      // chars_.draw(id, viewx, viewy, alpha);
      self.player.draw(id, viewx, viewy, alpha)
      // drops_.draw(id, viewx, viewy, alpha);
    },
  )
  @Layer.ids.each(fn(id) { self.player.draw(id, viewx, viewy, alpha) })

  //     combat_.draw(viewx, viewy, alpha);
  //     mob_combat_.draw(viewx, viewy, alpha);
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

  // combat_.update();
  // mob_combat_.update();
  self.backgrounds.unwrap().update()
  // effect_.update();
  self.tiles_objs.update()

  // reactors_.update(self.physics);
  // npcs_.update(self.physics);
  // mobs_.update(self.physics);
  // chars_.update(self.physics);
  // drops_.update(self.physics);
  self.player.update(self.physics) |> ignore
  self.portals.update(self.player.get_position())
  self.camera.update(self.player.get_position())
  if self.player.is_invincible() {
    return
  }

  // if (int32_t oid_id = mobs_.find_colliding(self.player.get_phobj())) {
  //     if (MobAttack attack = mobs_.create_attack(oid_id)) {
  //         MobAttackResult result = self.player.damage(attack);
  //         fn_take_damage(result, TakeDamagePacket::From::TOUCH);
  //     }
  // }
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

  // return npcs_.send_cursor(pressed, position, self.camera.position());
  if pressed {
    CursorState::CLICKING
  } else {
    CursorState::IDLE
  }
}

pub fn send_key(
  self : Stage,
  t : @KeyType.Id,
  action : Int,
  down : Bool
) -> Unit {
  if self.state != StageState::ACTIVE {
    return
  }
  match self.playable {
    Some(playable) =>
      match t {
        @KeyType.Id::ACTION => {
          if down {
            match @KeyAction.get_action_by_id?(action).unwrap() {
              @KeyAction.Id::UP =>
                // self.check_ladders(true)
                self.check_portals()
              // @KeyAction.Id::DOWN => self.check_ladders(false)
              // @KeyAction.Id::SIT => self.check_seats()
              // @KeyAction.Id::ATTACK => self.combat.use_move(0)
              // @KeyAction.Id::PICKUP => self.check_drops()
              _ => ()
            }
          }
          playable.send_action(
            @KeyAction.get_action_by_id?(action).unwrap(),
            down,
          )
        }
        // @KeyType.Id::SKILL => self.combat.use_move(action)
        // @KeyType.Id::ITEM => self.player.use_item(action)
        // @KeyType.Id::FACE => self.player.set_expression(action)
        _ => ()
      }
    None => ()
  }
}

fn check_portals(self : Stage) -> Unit {
  if self.player.is_attacking() {
    return
  }
  let playerpos = self.player.get_position()
  let warpinfo = self.portals.find_warp_at(playerpos)
  if warpinfo.intramap {
    let spawnpoint = self.portals.get_portal_by_name(warpinfo.toname)
    let startpos = self.physics.get_y_below(spawnpoint)
    self.player.respawn(startpos, self.map_info.is_underwater())
  } else if warpinfo.valid {
    new_change_map_packet(false, -1, warpinfo.name, false).dispatch()
    let stats = Stage::get().get_player().get_stats()
    stats.set_mapid(warpinfo.mapid)
  }

  // Sound(Sound::Name::PORTAL).play();
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
    Stage::get().get_player().recalc_stats(false)
  }
  UI::get().enable()
}

fn handle_stat(
  self : ChangeStatsHandler,
  stat : @MapleStat.Id,
  recv : @net.InPacket
) -> Bool! {
  let player = Stage::get().get_player()
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
        player.set_state(CharState::DIED)
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
