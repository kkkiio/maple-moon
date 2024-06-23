// app/src/main/cpp/src/Gameplay/Stage.h
// app/src/main/cpp/src/Gameplay/Stage.cpp

enum StageState {
  INACTIVE
  TRANSITION
  ACTIVE
} derive(Eq, Debug, Show)

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

  // CharStats stats = player_.get_stats();
  // level_before_ = stats.get_stat(MapleStat::Id::LEVEL);
  // exp_before_ = stats.get_exp();
}

fn load_map(self : Stage, mapid : Int) -> Unit {
  self.map_id = mapid
  let strid = @string_format.extend_id(mapid, 9)
  let prefix = (mapid / 100000000).to_string()
  let src = if mapid == -1 {
    ui_loader().load_res(["CashShopPreview.img"])
  } else {
    map_loader().load_res(["Map", "Map\(prefix)", "\(strid).img"])
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
  // Music(map_info_.get_bgm()).play();
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
  @Layer.ids.iter(
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
  @Layer.ids.iter(fn(id) { self.player.draw(id, viewx, viewy, alpha) })

  //     combat_.draw(viewx, viewy, alpha);
  //     mob_combat_.draw(viewx, viewy, alpha);
  self.portals.draw(viewpos, alpha)
  self.backgrounds.unwrap().drawforegrounds(viewx, viewy, alpha)
  //     effect_.draw();
  // 
}

pub fn transfer_player(self : Stage) -> Unit {
  // TODO
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

  // reactors_.update(physics_);
  // npcs_.update(physics_);
  // mobs_.update(physics_);
  // chars_.update(physics_);
  // drops_.update(physics_);
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
            match @KeyAction.get_action_by_id(action)!! {
              // @KeyAction.Id::UP => {
              //   self.check_ladders(true)
              //   self.check_portals()
              // }
              // @KeyAction.Id::DOWN => self.check_ladders(false)
              // @KeyAction.Id::SIT => self.check_seats()
              // @KeyAction.Id::ATTACK => self.combat.use_move(0)
              // @KeyAction.Id::PICKUP => self.check_drops()
              _ => ()
            }
          }
          playable.send_action(@KeyAction.get_action_by_id(action)!!, down)
        }
        // @KeyType.Id::SKILL => self.combat.use_move(action)
        // @KeyType.Id::ITEM => self.player.use_item(action)
        // @KeyType.Id::FACE => self.player.set_expression(action)
        _ => ()
      }
    None => ()
  }
}
