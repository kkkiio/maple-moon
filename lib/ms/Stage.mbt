// app/src/main/cpp/src/Gameplay/Stage.h
// app/src/main/cpp/src/Gameplay/Stage.cpp

enum StageState {
  INACTIVE
  TRANSITION
  ACTIVE
} derive(Eq, Debug, Show)

struct Stage {
  mut state : StageState
  mut backgrounds : MapBackgrounds?
  mut map_id : Int
  camera : Camera
  mut map_info : MapInfo
  mut portals : MapPortals
  mut physics : Physics
}

fn Stage::default() -> Stage {
  {
    state: StageState::INACTIVE,
    backgrounds: None,
    map_id: 10000,
    camera: Camera::new(),
    map_info: MapInfo::new(),
    physics: Physics::new(),
    portals: MapPortals::default(),
  }
}

fn Stage::get() -> Stage {
  stage
}

fn clear(self : Stage) -> Unit {
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
  }
  self.state = StageState::ACTIVE
}

fn load_map(self : Stage, mapid : Int) -> Unit {
  self.map_id = mapid
  let strid = @string_format.extend_id(mapid, 9)
  let prefix = (mapid / 100000000).to_string()
  let src = if mapid == -1 {
    ui_loader().load_res("CashShopPreview.img")
  } else {
    map_loader().load_res("Map/Map\(prefix)/\(strid).img")
  }
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
  // TODO
  let spawnpoint = self.portals.get_portal_by_id(portalid)
  let startpos = self.physics.get_y_below(spawnpoint)
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

  //     for (auto id : Layer::IDs) {
  //         tiles_objs_.draw(id, viewpos, alpha);
  //         reactors_.draw(id, viewx, viewy, alpha);
  //         npcs_.draw(id, viewx, viewy, alpha);
  //         mobs_.draw(id, viewx, viewy, alpha);
  //         chars_.draw(id, viewx, viewy, alpha);
  //         player_.draw(id, viewx, viewy, alpha);
  //         drops_.draw(id, viewx, viewy, alpha);
  //     }

  //     combat_.draw(viewx, viewy, alpha);
  //     mob_combat_.draw(viewx, viewy, alpha);
  self.portals.draw(viewpos, alpha)
  self.backgrounds.unwrap().drawforegrounds(viewx, viewy, alpha)
  //     effect_.draw();
  // 
}

fn update(self : Stage) -> Unit {
  if self.state != StageState::ACTIVE {
    return
  }

  // combat_.update();
  // mob_combat_.update();
  self.backgrounds.unwrap().update()
  // effect_.update();
  // tiles_objs_.update();

  // reactors_.update(physics_);
  // npcs_.update(physics_);
  // mobs_.update(physics_);
  // chars_.update(physics_);
  // drops_.update(physics_);
  // player_.update(physics_);

  // self.portals.update(player_.get_position());
  // self.camera.update(player_.get_position());

  // if (player_.is_invincible()) {
  //     return;
  // }

  // if (int32_t oid_id = mobs_.find_colliding(player_.get_phobj())) {
  //     if (MobAttack attack = mobs_.create_attack(oid_id)) {
  //         MobAttackResult result = player_.damage(attack);
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
