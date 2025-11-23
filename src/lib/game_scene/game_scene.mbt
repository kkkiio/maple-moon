///|
enum StageState {
  INACTIVE
  TRANSITION(
    portal_id~ : Int,
    loading_map~ : @utils.Future[Result[@map.SceneMap, Error]]
  )
  ACTIVE(
    tiles_objs~ : @map.MapTilesObjs,
    backgrounds~ : @map.Backgrounds,
    physics~ : @physics.Physics,
    map_info~ : @map.MapInfo,
    portals~ : @map.MapPortals,
    enter_portal_id~ : Int
  )
}

///|
pub(all) struct Stage {
  // camera : Camera
  map_portals_animations : @map.MapPortalAnimations
  mut player : @player.Player
  mut state : StageState
  mut map_id : Int
  // npcs : @npc.MapNpcs
  // quests : @quest.MapQuests
  // mobs : @monster.MapMobs
  // drops : @drop.MapDrops
  // inventory : @inventory.Inventory
  // damage_number_set : @ui.NumberSet
  // combat : @combat_impl2.Combat
  // char_look_module : @char_look.Module
  // skill_book_module : @skill_book.Module
  // char_stats_module : @char_stats.Module
  // network : @net.Network
  map_change_listeners : Array[(@map.SceneMap) -> Bool]
  io_service : @io_task.IOService
  // bullet_module : @bullet.Module
}

///|
pub fn Stage::new(
  map_portals_animations : @map.MapPortalAnimations,
  // mobs : @monster.MapMobs,
  // drops : @drop.MapDrops,
  // inventory : @inventory.Inventory,
  // npcs : @npc.MapNpcs,
  // quests : @quest.MapQuests,
  // char_look_module : @char_look.Module,
  // skill_book_module : @skill_book.Module,
  // char_stats_module : @char_stats.Module,
  // damage_number_set : @ui.NumberSet,
  // network : @net.Network,
  io_service : @io_task.IOService,
  // bullet_module : @bullet.Module,
  // combat : @combat_impl2.Combat,
  player : @player.Player,
) -> Stage {
  {
    map_portals_animations,
    // camera: Camera::new(),
    player,
    state: StageState::INACTIVE,
    map_id: 10000,
    // npcs,
    // quests,
    // damage_number_set,
    // combat,
    // mobs,
    // drops,
    // inventory,
    // char_look_module,
    // skill_book_module,
    // char_stats_module,
    // network,
    map_change_listeners: Array::new(),
    io_service,
    // bullet_module,
  }
}

///|
fn Stage::clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
  // self.chars.clear()
  // self.npcs.clear()
  // self.quests.clear()
  // self.mobs.clear()
  // self.drops.clear()
  // self.reactors.clear()
}

///|
pub fn Stage::load(self : Stage, map_id : Int, portal_id : Int) -> Unit {
  match self.state {
    StageState::INACTIVE => {
      self.map_id = map_id
      let loading_map = self.io_service.submit(fn() {
        @map.load_map(map_id, self.map_portals_animations)
      })
      self.state = StageState::TRANSITION(portal_id~, loading_map~)
    }
    StageState::TRANSITION(_) =>
      // TODO: respawn?
      @log.warn({ "map_id": map_id }, "map already loading")
    StageState::ACTIVE(_) => ()
  }
}

///|
pub fn Stage::set_player_stage(
  self : Stage,
  entry : @character.CharEntry,
  cooldowns : Map[Int, Int],
  callback : (@player.Player) -> Unit raise,
) -> Unit {
  // self.combat.set_cooldowns(cooldowns)
  // self.io_service.execute(
  //   fn() {
  //     let look = self.char_look_module.load_char_look(entry.look)
  //     let player = @player.Player::load(
  //       entry,
  //       self.inventory,
  //       look,
  //       self.damage_number_set,
  //       fn(job) { self.skill_book_module.load_player_skill_book(job) },
  //       fn(job) {
  //         self.char_stats_module.new_char_stats(
  //           entry.stats,
  //           fn() { @character.get_weapon_type_in_look(look) },
  //           job,
  //         )
  //       },
  //       self.network,
  //     )
  //     self.player = Some(player)
  //     callback(player)
  //   },
  //   on_error=fn(e) { @log.error({ "error": e }, "set_player_stage") },
  // )
}

///|
fn Stage::respawn(
  self : Stage,
  portal_id : Int,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics,
) -> Unit {
  // TODO: Music
  let spawnpoint = portals.get_portal_pos_by_id(portal_id)
  let startpos = physics.get_y_below(spawnpoint)
  let left = map_info.get_walls().first().to_double()
  let right = map_info.get_walls().second().to_double()
  let top = map_info.get_borders().first().to_double()
  let bottom = map_info.get_borders().second().to_double()
  @log.info(
    {
      "spawnpoint": spawnpoint,
      "startpos": startpos,
      "left": left,
      "right": right,
      "top": top,
      "bottom": bottom,
    },
    "respawn",
  )
  self.player.respawn(startpos, map_info.is_underwater())
  // self.camera.set_position(startpos)
  @camera.attach_entity(self.player.entity, @selene_math.Vec2D(16.0, 16.0))
  // self.camera.set_view(map_info.get_walls(), map_info.get_borders())
  @camera.set_limits(left~, right~, top~, bottom~)
}

///|
fn set_sprites(
  backgrounds : @map.Backgrounds,
  tiles_objs : @map.MapTilesObjs,
  world_size : @selene_math.Vec2D,
) -> Unit {
  // let viewpos = self.camera.get_position(alpha~)
  // let viewrpos = self.camera.real_position(alpha)
  // let viewx = viewrpos.0
  // let viewy = viewrpos.1
  // @map.drawbackgrounds(backgrounds.backs, viewx, viewy, alpha)
  for i, background in backgrounds.backs {
    // background.draw(viewx, viewy, alpha)
    let z = @graphics.BG_ZINDEX + i
    background.set_sprites(world_size, z)
  }
  // let player = self.player.unwrap()
  // for id in @map_layer.ids {
  tiles_objs.set_sprites()
  //   // reactors_.draw(id, viewx, viewy, alpha);
  //   self.npcs.draw(id, viewx, viewy, alpha)
  //   self.quests.draw(id, viewx, viewy, alpha)
  //   self.mobs.draw(id, viewx, viewy, alpha)
  //   // chars_.draw(id, viewx, viewy, alpha);
  //   player.draw(id, viewx, viewy, alpha)
  //   self.drops.draw(id, viewx, viewy, alpha)
  // }
  // self.combat.draw(viewx, viewy, alpha)
  // portals.draw(viewpos, alpha)
  // @map.drawforegrounds(backgrounds.fores, viewx, viewy, alpha)
  // //     effect_.draw();
}

///|
fn Stage::update(self : Stage) -> Unit raise {
  // let (
  //   tiles_objs,
  //   backgrounds,
  //   physics,
  //   portals, // Make sure to destructure map_info here
  //   map_info,
  // ) = match self.state {
  //   StageState::ACTIVE(
  //     tiles_objs~,
  //     backgrounds~,
  //     physics~,
  //     portals~,
  //     map_info~,
  //     ..
  //   ) => (tiles_objs, backgrounds, physics, portals, map_info)
  //   StageState::INACTIVE => return ()
  //   StageState::TRANSITION(portal_id~, loading_map~) =>
  //     match loading_map.poll() {
  //       Some(res) => {
  //         let sence_map = res.unwrap_or_error()
  //         self.state = StageState::ACTIVE(
  //           tiles_objs=sence_map.tiles_objs,
  //           backgrounds=sence_map.backgrounds,
  //           physics=sence_map.physics,
  //           map_info=sence_map.map_info,
  //           portals=sence_map.portals,
  //           enter_portal_id=portal_id,
  //         )
  //         self.respawn(
  //           portal_id,
  //           sence_map.map_info,
  //           sence_map.portals,
  //           sence_map.physics,
  //         )
  //         self.quests.set_player(self.player.unwrap())
  //         self.map_change_listeners.retain(fn(listener) { listener(sence_map) })
  //         return // for simplicity, just wait for the next update
  //       }
  //       None => return ()
  //     }
  // }
  // self.combat.update()
  // @map.update_backgrounds(backgrounds)
  // // effect_.update();
  // tiles_objs.update()

  // // reactors_.update(self.physics);
  // self.npcs.update(physics)
  // self.quests.update(physics)
  // self.mobs.update(physics, self.network)
  // // chars_.update(self.physics);
  // self.drops.update(physics)
  // let player = self.player.unwrap()
  // player.update(physics, map_info) |> ignore // Pass map_info here
  // portals.update(player.character.get_position())
  // self.camera.update(player.character.get_position())
  // if player.is_invincible() {
  //   return
  // }
  // match self.mobs.find_colliding(player.character.get_phobj().moving_object) {
  //   Some(oid_id) =>
  //     match self.mobs.create_attack(oid_id) {
  //       Some(attack) => {
  //         let result = player.damage(attack)
  //         self.network.send_message(
  //           new_take_damage_packet_from_mob(result, TakeDamageFrom::TOUCH),
  //         )
  //       }
  //       None => ()
  //     }
  //   None => ()
  // }
  ...
}

///|
fn Stage::send_cursor(
  self : Stage,
  pressed : Bool,
  position : @struct.Point[Int],
) -> @ui.CursorState {
  // if self.npcs.send_cursor(pressed, position, self.camera.get_position())
  //   is Some(state) {
  //   return state
  // }
  // if self.quests.send_cursor(pressed, position, self.camera.get_position())
  //   is Some(state) {
  //   return state
  // }
  // if pressed {
  //   @ui.CursorState::CLICKING
  // } else {
  //   @ui.CursorState::IDLE
  // }
  ...
}

///|
pub fn player_state_system(_delta : Double) -> Unit {
  guard stage_ref.val
    is Some({ state: StageState::ACTIVE(physics~, map_info~, ..), player, .. }) else {
    return
  }
  // match mapping {
  //   ACTION(action) => {
  //     if down {
  //       match action {
  //         @keyboard.BasicActionId::UP =>
  //           self.check_portals(map_info, portals, physics)
  //         // @keyboard.ActionId::SIT => self.check_seats()
  //         @keyboard.BasicActionId::ATTACK => () //self.combat.use_move(player, 0)
  //         @keyboard.BasicActionId::PICKUP => self.check_drops(player)
  //         _ => ()
  //       }
  //     }
  //   }
  //   SKILL(skill_id) => () //self.combat.use_move(player, skill_id)
  //   ITEM(item_id) => () //self.inventory.use_item(item_id)
  //   // @keyboard.Id::FACE => self.player.set_expression(action)
  //   _ => ()
  // }
  for
    it in [
      (@inputs.ArrowUp, @keyboard.BasicActionId::UP),
      (@inputs.ArrowDown, @keyboard.BasicActionId::DOWN),
      (@inputs.ArrowLeft, @keyboard.BasicActionId::LEFT),
      (@inputs.ArrowRight, @keyboard.BasicActionId::RIGHT),
      (@inputs.Space, @keyboard.BasicActionId::JUMP),
    ] {
    let (code, action) = it
    if @inputs.is_just_pressed(code) {
      player.send_action(action, true)
    } else if @inputs.is_just_released(code) {
      player.send_action(action, false)
    }
  }
  player.update(physics, map_info)
}

///|
fn Stage::check_portals(
  self : Stage,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics,
) -> Unit {
  let player = self.player
  if player.is_attacking() {
    return
  }
  let playerpos = player.character.get_position()
  let warpinfo = portals.find_warp_at(playerpos)
  if warpinfo.intramap {
    let spawnpoint = portals.get_portal_by_name(warpinfo.toname)
    let startpos = physics.get_y_below(spawnpoint)
    player.respawn(startpos, map_info.is_underwater())
    // } else if warpinfo.valid {
  } else {
    // let message : @player.ChangeMapMessage = {
    //   died: false,
    //   target_id: -1,
    //   target_p: warpinfo.name,
    //   use_wheel: false,
    // }
    // self.network.send_message(message, log_level=@log.Level::INFO)
    // let stats = player.get_stats()
    // stats.set_map_id(warpinfo.mapid)
  }

  // Sound(Sound::Name::PORTAL).play();
}

///|
priv struct PlayerMapTransferMessage(Unit) derive(Show)

///|
impl @net.OutMessage for PlayerMapTransferMessage with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::PLAYER_MAP_TRANSFER)
}

///|
pub fn Stage::get_mobs(self : Stage) -> @monster.MapMobs {
  ...
}

///|
pub fn Stage::get_inventory(self : Stage) -> @inventory.Inventory {
  ...
  // self.inventory
}

///|
/// Tells the server that the player took damage.
priv enum TakeDamageFrom {
  TOUCH
} derive(Show)

///|
fn TakeDamageFrom::int_value(self : TakeDamageFrom) -> Int {
  match self {
    TakeDamageFrom::TOUCH => -1
  }
}

///|
/// Message sent when player takes damage
priv struct TakeDamageMessage {
  from : TakeDamageFrom
  element : Int
  damage : Int
  mobid : Int
  oid : Int
  direction : Int
} derive(Show)

///|
impl @net.OutMessage for TakeDamageMessage with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::TAKE_DAMAGE)
  p
  ..write_time()
  ..write_byte(self.from.int_value().to_byte())
  ..write_byte(self.element.to_byte())
  ..write_int(self.damage)
  ..write_int(self.mobid)
  ..write_int(self.oid)
  ..write_byte(self.direction.to_byte())
  p
}

///|
/// From mob attack result.
fn new_take_damage_packet_from_mob(
  result : @combat.MobAttackResult,
  from : TakeDamageFrom,
) -> TakeDamageMessage {
  {
    from,
    element: 0,
    damage: result.damage,
    mobid: result.mobid,
    oid: result.oid,
    direction: result.direction,
  }
}

///|
fn Stage::check_drops(self : Stage, player : @player.Player) -> Unit {
  ...
  // for it in self.drops.list_loot_at(player.character.get_position()) {
  //   let (drop_oid, drop_pos) = it
  //   self.network.send_message({ oid: drop_oid, position: drop_pos })
  // }
}

///|
priv struct PickupItemMessage {
  oid : Int
  position : @struct.Point[Int]
} derive(Show)

///|
impl @net.OutMessage for PickupItemMessage with pack(self) -> @net.OutPacket {
  let p = @net.OutPacket::new(@net.ClientOpcode::PICKUP_ITEM)
  p
  ..write_int(0)
  ..write_byte((0).to_byte())
  ..write_point(self.position)
  ..write_int(self.oid)
  p
}

///|
pub fn Stage::transition(self : Stage, mapid : Int, portalid : Int) -> Unit {
  self.clear()
  // @graphics.GraphicsGL::get().clear()
  self.load(mapid, portalid)
  // self.network.send_message(PlayerMapTransferMessage(()))
}

///|
pub fn Stage::listen_map_change(
  self : Stage,
  on_change : (@map.SceneMap) -> Bool,
) -> Unit {
  self.map_change_listeners.push(on_change)
}

///|
/// reset player position. for debug
pub fn Stage::reset_player_position(self : Stage) -> Unit {
  guard self.state
    is StageState::ACTIVE(portals~, map_info~, enter_portal_id~, physics~, ..) else {
    return
  }
  self.respawn(enter_portal_id, map_info, portals, physics)
}

///|
let stage_ref : Ref[Stage?] = Ref::new(None)

///|
pub fn game_scene_system(_delta : Double) -> Unit {
  guard @game_state.game_state.state
    is @game_state.GameStateType::Game(map_id~, portal_id~, char_look~) else {
    stage_ref.val = None
    return
  }
  let stage = match stage_ref.val {
    Some(stage) => stage
    None => {
      let map_module = @map.Module::load()
      let stats : @char_stats.CharStats = @char_stats.CharStats::new(
        @char_stats.StatsEntry::default(),
        fn() { @weapon.Type::NONE },
        @job.Job::new(0, @job.Level::BEGINNER, Map::new()),
        Map::new(),
        Map::new(),
        Map::new(),
      )
      let number_set : @ui.NumberSet = @ui.NumberSet::load() catch {
        e => {
          @log.error({ "error": e }, "load number set")
          panic()
        }
      }
      let entity = char_look.get_root_entity()
      entity.respawn()
      let player : @player.Player = @player.Player::new(
        entity, 1, "kkkiio", char_look, number_set, stats,
      )
      let stage = Stage::new(
        map_module.get_portals_animations(),
        @io_task.IOService::new(),
        player,
      )
      stage_ref.val = Some(stage)
      stage
    }
  }
  match stage.state {
    StageState::INACTIVE => {
      stage.transition(map_id, portal_id)
      return
    }
    StageState::TRANSITION(portal_id~, loading_map~) => {
      guard loading_map.poll() is Some(res) else { return }
      let sence_map = match res {
        Ok(sence_map) => sence_map
        Err(e) => {
          @log.error({ "error": e, "map_id": map_id }, "fail to load map")
          panic()
        }
      }
      stage.state = StageState::ACTIVE(
        tiles_objs=sence_map.tiles_objs,
        backgrounds=sence_map.backgrounds,
        physics=sence_map.physics,
        map_info=sence_map.map_info,
        portals=sence_map.portals,
        enter_portal_id=portal_id,
      )
      let width = sence_map.map_info.get_walls().delta()
      let height = sence_map.map_info.get_borders().delta()
      set_sprites(
        sence_map.backgrounds,
        sence_map.tiles_objs,
        @selene_math.Vec2D(width.to_double(), height.to_double()),
      )
      stage.respawn(
        portal_id,
        sence_map.map_info,
        sence_map.portals,
        sence_map.physics,
      )
      // stage.quests.set_player(stage.player.unwrap())
      stage.map_change_listeners.retain(fn(listener) { listener(sence_map) })
      return // for simplicity, just wait for the next update
    }
    StageState::ACTIVE(..) => ()
  }
}
