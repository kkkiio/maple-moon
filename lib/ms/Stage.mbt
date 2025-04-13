///|
enum StageState {
  INACTIVE
  TRANSITION(
    portal_id~ : Int,
    loading_map~ : @utils.Future[Result[@map.MapStruct, Error]]
  )
  ACTIVE(
    tiles_objs~ : @map.MapTilesObjs,
    backgrounds~ : @map.Backgrounds,
    physics~ : @physics.Physics,
    map_info~ : @map.MapInfo,
    portals~ : @map.MapPortals
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
  mobs : @monster.MapMobs
  drops : @drop.MapDrops
  inventory : @inventory.Inventory
  damage_number_set : @ui.NumberSet
  mut combat : Combat?
  char_look_module : @char_look.Module
  skill_book_module : @skill_book.Module
  char_stats_module : @char_stats.Module
  add_task_fn : (@utils.Future[Unit]) -> Unit
  packet_processor : @net.PacketProcessor
}

///|
pub fn Stage::new(
  map_portals_animations : @map.MapPortalAnimations,
  mobs : @monster.MapMobs,
  drops : @drop.MapDrops,
  inventory : @inventory.Inventory,
  npcs : @npc.MapNpcs,
  char_look_module : @char_look.Module,
  skill_book_module : @skill_book.Module,
  char_stats_module : @char_stats.Module,
  damage_number_set : @ui.NumberSet,
  add_task_fn : (@utils.Future[Unit]) -> Unit,
  packet_processor : @net.PacketProcessor
) -> Stage {
  {
    map_portals_animations,
    camera: Camera::new(),
    player: None,
    state: StageState::INACTIVE,
    map_id: 10000,
    npcs,
    damage_number_set,
    combat: None,
    mobs,
    drops,
    inventory,
    char_look_module,
    skill_book_module,
    char_stats_module,
    add_task_fn,
    packet_processor,
  }
}

///|
pub fn clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
  // self.chars.clear()
  self.npcs.clear()
  self.mobs.clear()
  self.drops.clear()
  // self.reactors.clear()
}

///|
pub fn load(self : Stage, map_id : Int, portal_id : Int) -> Unit {
  match self.state {
    StageState::INACTIVE => {
      self.map_id = map_id
      let loading_map = @map.load_map(map_id, self.map_portals_animations)
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
  callback : (@player.Player) -> Unit!
) -> Unit {
  let player_f = self.char_look_module
    .load_char_look(entry.look)
    .bind(fn(look) {
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
      ).tap(fn(player) {
        self.player = Some(player)
        self.combat = Some(
          Combat::new(
            self.damage_number_set,
            self.mobs,
            self.packet_processor,
            self.add_task_fn,
          ),
        )
      })
    })
  (self.add_task_fn)(
    player_f.map(fn(player) {
      match callback?(player) {
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
pub fn get_npcs(self : Stage) -> @npc.MapNpcs {
  self.npcs
}

///|
pub fn respawn(
  self : Stage,
  portal_id : Int,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics
) -> Unit {
  // TODO: Music
  let spawnpoint = portals.get_portal_by_id(portal_id)
  let startpos = physics.get_y_below(spawnpoint)
  @log.info({ "spawnpoint": spawnpoint, "startpos": startpos }, "respawn")
  self.player.unwrap().respawn(startpos, map_info.is_underwater())
  self.camera.set_position(startpos)
  self.camera.set_view(map_info.get_walls(), map_info.get_borders())
}

///|
pub fn draw(self : Stage, alpha : Double) -> Unit {
  guard let StageState::ACTIVE(tiles_objs~, backgrounds~, portals~, ..) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(_) => return
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
pub fn transfer_player() -> Unit {
  new_player_map_transfer_packet().dispatch()
}

///|
fn update(self : Stage) -> Unit! { // Make sure to destructure map_info here
  guard let StageState::ACTIVE(
    tiles_objs~,
    backgrounds~,
    physics~,
    portals~,
    map_info~,
    ..
  ) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(portal_id~, loading_map~) =>
      match loading_map.poll() {
        Some(map_struct) => {
          let map_struct = map_struct.unwrap_or_error!()
          self.state = StageState::ACTIVE(
            tiles_objs=map_struct.tiles_objs,
            backgrounds=map_struct.backgrounds,
            physics=map_struct.physics,
            map_info=map_struct.map_info,
            portals=map_struct.portals,
          )
          self.respawn(
            portal_id,
            map_struct.map_info,
            map_struct.portals,
            map_struct.physics,
          )
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
  self.mobs.update(physics)
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
          new_take_damage_packet_from_mob(result, TakeDamageFrom::TOUCH).dispatch()
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
  // TODO: statusbar
  self.npcs.send_cursor(pressed, position, self.camera.get_position())
}

///|
pub fn send_key(
  self : Stage,
  t : @keyboard.KeyType,
  action : Int,
  down : Bool
) -> Unit {
  guard let StageState::ACTIVE(physics~, map_info~, portals~, ..) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(_) => return
  }
  match self.player {
    Some(player) =>
      match t {
        @keyboard.KeyType::ACTION => {
          let action = @keyboard.BasicActionId::from_int(action).unwrap() // TODO: handle error
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
        @keyboard.KeyType::SKILL =>
          self.combat.unwrap().use_move(player, action)
        // @keyboard.Id::ITEM => self.player.use_item(action)
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
  } else if warpinfo.valid {
    let message : @player.ChangeMapMessage = {
      died: false,
      target_id: -1,
      target_p: warpinfo.name,
      use_wheel: false,
    }
    self.packet_processor.send_message(message, log_level=@log.Level::INFO)
    let stats = player.get_stats()
    stats.set_map_id(warpinfo.mapid)
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
pub fn new_player_map_transfer_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_MAP_TRANSFER)
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
}

///|
fn int_value(self : TakeDamageFrom) -> Int {
  match self {
    TakeDamageFrom::TOUCH => -1
  }
}

///|
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

///| From mob attack result.
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

///|
fn check_drops(self : Stage, player : @player.Player) -> Unit {
  for it in self.drops.list_loot_at(player.character.get_position()) {
    let (drop_oid, drop_pos) = it
    new_pickup_item_packet(drop_oid, drop_pos).dispatch()
  }
}

///|
fn new_pickup_item_packet(
  oid : Int,
  position : @struct.Point[Int]
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PICKUP_ITEM)
  ..write_int(0)
  ..write_byte((0).to_byte())
  ..write_point(position)
  ..write_int(oid)
}

///|
pub fn transition(self : Stage, mapid : Int, portalid : Int) -> Unit {
  self.clear()
  @graphics.GraphicsGL::get().clear()
  self.load(mapid, portalid)
  transfer_player()
}
