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
  camera : Camera
  map_portals_animations : @map.MapPortalAnimations
  mut player : @player.Player?
  mut state : StageState
  mut map_id : Int
  npcs : @npc.MapNpcs
  quests : @quest.MapQuests
  mobs : @monster.MapMobs
  drops : @drop.MapDrops
  inventory : @inventory.Inventory
  damage_number_set : @ui.NumberSet
  mut combat : @combat_impl2.Combat?
  char_look_module : @char_look.Module
  skill_book_module : @skill_book.Module
  char_stats_module : @char_stats.Module
  add_task_fn : (@utils.Future[Unit]) -> Unit
  network : @net.Network
  map_change_listeners : Array[(@map.SceneMap) -> Bool]
  string_loader : @resource.SyncLoader
  io_service : @io_task.IOService
  bullet_module : @bullet.Module
}

///|
pub fn Stage::new(
  map_portals_animations : @map.MapPortalAnimations,
  mobs : @monster.MapMobs,
  drops : @drop.MapDrops,
  inventory : @inventory.Inventory,
  npcs : @npc.MapNpcs,
  quests : @quest.MapQuests,
  char_look_module : @char_look.Module,
  skill_book_module : @skill_book.Module,
  char_stats_module : @char_stats.Module,
  damage_number_set : @ui.NumberSet,
  add_task_fn : (@utils.Future[Unit]) -> Unit,
  network : @net.Network,
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService,
  bullet_module : @bullet.Module
) -> Stage {
  {
    map_portals_animations,
    camera: Camera::new(),
    player: None,
    state: StageState::INACTIVE,
    map_id: 10000,
    npcs,
    quests,
    damage_number_set,
    combat: None,
    mobs,
    drops,
    inventory,
    char_look_module,
    skill_book_module,
    char_stats_module,
    add_task_fn,
    network,
    map_change_listeners: Array::new(),
    string_loader,
    io_service,
    bullet_module,
  }
}

///|
fn clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
  // self.chars.clear()
  self.npcs.clear()
  self.quests.clear()
  self.mobs.clear()
  self.drops.clear()
  // self.reactors.clear()
}

///|
pub fn load(self : Stage, map_id : Int, portal_id : Int) -> Unit {
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
pub fn set_player_stage(
  self : Stage,
  entry : @character.CharEntry,
  cooldowns : Map[Int, Int],
  callback : (@player.Player) -> Unit raise
) -> Unit {
  let player_f = self.io_service
    .submit(async fn() { self.char_look_module.load_char_look(entry.look) })
    .bind(fn(look) {
      let look = look.unwrap() // TODO: handle error
      @player.Player::load(
        entry,
        self.inventory,
        look,
        self.damage_number_set,
        fn(job) { self.skill_book_module.load_skill_book(job) },
        fn(job) {
          self.char_stats_module.new_char_stats(
            entry.stats,
            fn() { @character.get_weapon_type_in_look(look) },
            job,
          )
        },
        self.network,
        self.string_loader,
        self.io_service,
      ).tap(fn(player) {
        self.player = Some(player)
        self.combat = Some(
          @combat_impl2.Combat::new(
            self.damage_number_set,
            self.mobs,
            self.network,
            cooldowns,
            self.string_loader,
            self.io_service,
            self.bullet_module,
          ),
        )
      })
    })
  (self.add_task_fn)(
    player_f.map(fn(player) {
      match (try? callback(player)) {
        Ok(_) => ()
        Err(e) => @log.error({ "error": e }, "set_player_stage")
      }
    }),
  )
}

///|
pub fn get_player(self : Stage) -> @player.Player? {
  self.player
}

///|
fn respawn(
  self : Stage,
  portal_id : Int,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics
) -> Unit {
  // TODO: Music
  let spawnpoint = portals.get_portal_pos_by_id(portal_id)
  let startpos = physics.get_y_below(spawnpoint)
  @log.info({ "spawnpoint": spawnpoint, "startpos": startpos }, "respawn")
  self.player.unwrap().respawn(startpos, map_info.is_underwater())
  self.camera.set_position(startpos)
  self.camera.set_view(map_info.get_walls(), map_info.get_borders())
}

///|
pub fn draw(self : Stage, alpha : Double) -> Unit {
  guard self.state
    is StageState::ACTIVE(tiles_objs~, backgrounds~, portals~, ..) else {
    return
  }
  let viewpos = self.camera.get_position(alpha~)
  let viewrpos = self.camera.real_position(alpha)
  let viewx = viewrpos.x
  let viewy = viewrpos.y
  @map.drawbackgrounds(backgrounds.backs, viewx, viewy, alpha)
  let player = self.player.unwrap()
  for id in @map_layer.ids {
    tiles_objs.draw(id, viewpos, alpha)
    // reactors_.draw(id, viewx, viewy, alpha);
    self.npcs.draw(id, viewx, viewy, alpha)
    self.quests.draw(id, viewx, viewy, alpha)
    self.mobs.draw(id, viewx, viewy, alpha)
    // chars_.draw(id, viewx, viewy, alpha);
    player.draw(id, viewx, viewy, alpha)
    self.drops.draw(id, viewx, viewy, alpha)
  }
  self.combat.unwrap().draw(viewx, viewy, alpha)
  portals.draw(viewpos, alpha)
  @map.drawforegrounds(backgrounds.fores, viewx, viewy, alpha)
  //     effect_.draw();
}

///|
fn update(self : Stage) -> Unit raise {
  let (
    tiles_objs,
    backgrounds,
    physics,
    portals, // Make sure to destructure map_info here
    map_info,
  ) = match self.state {
    StageState::ACTIVE(
      tiles_objs~,
      backgrounds~,
      physics~,
      portals~,
      map_info~,
      ..
    ) => (tiles_objs, backgrounds, physics, portals, map_info)
    StageState::INACTIVE => return ()
    StageState::TRANSITION(portal_id~, loading_map~) =>
      match loading_map.poll() {
        Some(res) => {
          let sence_map = res.unwrap_or_error()
          self.state = StageState::ACTIVE(
            tiles_objs=sence_map.tiles_objs,
            backgrounds=sence_map.backgrounds,
            physics=sence_map.physics,
            map_info=sence_map.map_info,
            portals=sence_map.portals,
            enter_portal_id=portal_id,
          )
          self.respawn(
            portal_id,
            sence_map.map_info,
            sence_map.portals,
            sence_map.physics,
          )
          self.quests.set_player(self.player.unwrap())
          self.map_change_listeners.retain(fn(listener) { listener(sence_map) })
          return // for simplicity, just wait for the next update
        }
        None => return ()
      }
  }
  self.combat.unwrap().update()
  @map.update_backgrounds(backgrounds)
  // effect_.update();
  tiles_objs.update()

  // reactors_.update(self.physics);
  self.npcs.update(physics)
  self.quests.update(physics)
  self.mobs.update(physics, self.network)
  // chars_.update(self.physics);
  self.drops.update(physics)
  let player = self.player.unwrap()
  player.update(physics, map_info) |> ignore // Pass map_info here
  portals.update(player.character.get_position())
  self.camera.update(player.character.get_position())
  if player.is_invincible() {
    return
  }
  match self.mobs.find_colliding(player.character.get_phobj().moving_object) {
    Some(oid_id) =>
      match self.mobs.create_attack(oid_id) {
        Some(attack) => {
          let result = player.damage(attack)
          self.network.send_message(
            new_take_damage_packet_from_mob(result, TakeDamageFrom::TOUCH),
          )
        }
        None => ()
      }
    None => ()
  }
}

///|
fn send_cursor(
  self : Stage,
  pressed : Bool,
  position : @struct.Point[Int]
) -> @ui.CursorState {
  if self.npcs.send_cursor(pressed, position, self.camera.get_position())
    is Some(state) {
    return state
  }
  if self.quests.send_cursor(pressed, position, self.camera.get_position())
    is Some(state) {
    return state
  }
  if pressed {
    @ui.CursorState::CLICKING
  } else {
    @ui.CursorState::IDLE
  }
}

///|
pub fn send_key(self : Stage, mapping : @keyboard.Mapping, down : Bool) -> Unit {
  guard self.state is StageState::ACTIVE(physics~, map_info~, portals~, ..) else {
    return
  }
  match self.player {
    Some(player) =>
      match mapping {
        ACTION(action) => {
          if down {
            match action {
              @keyboard.BasicActionId::UP =>
                self.check_portals(map_info, portals, physics)
              // @keyboard.ActionId::SIT => self.check_seats()
              @keyboard.BasicActionId::ATTACK =>
                self.combat.unwrap().use_move(player, 0)
              @keyboard.BasicActionId::PICKUP => self.check_drops(player)
              _ => ()
            }
          }
          player.send_action(action, down)
        }
        SKILL(skill_id) => self.combat.unwrap().use_move(player, skill_id)
        ITEM(item_id) => self.inventory.use_item(item_id)
        // @keyboard.Id::FACE => self.player.set_expression(action)
        _ => ()
      }
    None => ()
  }
}

///|
fn check_portals(
  self : Stage,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics
) -> Unit {
  let player = self.player.unwrap()
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
    let message : @player.ChangeMapMessage = {
      died: false,
      target_id: -1,
      target_p: warpinfo.name,
      use_wheel: false,
    }
    self.network.send_message(message, log_level=@log.Level::INFO)
    // let stats = player.get_stats()
    // stats.set_map_id(warpinfo.mapid)
  }

  // Sound(Sound::Name::PORTAL).play();
}

///|
fn get_character(self : Stage, cid : Int) -> @character.Character? {
  match self.player {
    Some(player) =>
      if player.character.get_oid() == cid {
        return Some(player.character)
      }
    None => ()
  }
  // TODO: chars
  None
}

///|
priv type PlayerMapTransferMessage Unit derive(Show)

///|
impl @net.OutMessage for PlayerMapTransferMessage with pack(self) -> @net.OutPacket {
  ignore(self)
  @net.OutPacket::new(@net.ClientOpcode::PLAYER_MAP_TRANSFER)
}

///|
pub fn get_mobs(self : Stage) -> @monster.MapMobs {
  self.mobs
}

///|
pub fn get_inventory(self : Stage) -> @inventory.Inventory {
  self.inventory
}

///| Tells the server that the player took damage.
priv enum TakeDamageFrom {
  TOUCH
} derive(Show)

///|
fn int_value(self : TakeDamageFrom) -> Int {
  match self {
    TakeDamageFrom::TOUCH => -1
  }
}

///| Message sent when player takes damage
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

///| From mob attack result.
fn new_take_damage_packet_from_mob(
  result : @combat.MobAttackResult,
  from : TakeDamageFrom
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
fn check_drops(self : Stage, player : @player.Player) -> Unit {
  for it in self.drops.list_loot_at(player.character.get_position()) {
    let (drop_oid, drop_pos) = it
    self.network.send_message({ oid: drop_oid, position: drop_pos })
  }
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
pub fn transition(self : Stage, mapid : Int, portalid : Int) -> Unit {
  self.clear()
  @graphics.GraphicsGL::get().clear()
  self.load(mapid, portalid)
  self.network.send_message(PlayerMapTransferMessage(()))
}

///|
pub fn listen_map_change(
  self : Stage,
  on_change : (@map.SceneMap) -> Bool
) -> Unit {
  self.map_change_listeners.push(on_change)
}

///| reset player position. for debug
pub fn reset_player_position(self : Stage) -> Unit {
  guard self.state
    is StageState::ACTIVE(portals~, map_info~, enter_portal_id~, physics~, ..) else {
    return
  }
  self.respawn(enter_portal_id, map_info, portals, physics)
}
