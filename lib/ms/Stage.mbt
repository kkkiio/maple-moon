enum StageState {
  INACTIVE
  TRANSITION(~portal_id : Int, ~poll_fn : () -> @map.MapStruct?!)
  ACTIVE(
    ~tiles_objs : @map.MapTilesObjs,
    ~backgrounds : @map.MapBackgrounds,
    ~physics : @physics.Physics,
    ~map_info : @map.MapInfo,
    ~portals : @map.MapPortals
  )
}

pub struct Stage {
  camera : Camera
  mut player : @player.Player?
  mut state : StageState
  mut map_id : Int
  npcs : MapNpcs
  mobs : @monster.MapMobs
  drops : @drop.MapDrops
  inventory : @inventory.Inventory
  damage_number_set : @combat_ui.DamageNumberSet
  mut combat : Combat?
  mut start : TimePoint
}

pub fn Stage::new(
  mobs : @monster.MapMobs,
  drops : @drop.MapDrops,
  inventory : @inventory.Inventory
) -> Stage {
  {
    camera: Camera::new(),
    player: None,
    state: StageState::INACTIVE,
    map_id: 10000,
    npcs: MapNpcs::new(),
    damage_number_set: @combat_ui.DamageNumberSet::new(),
    combat: None,
    mobs,
    drops,
    inventory,
    start: TimePoint::default(),
  }
}

pub fn Stage::get() -> Stage {
  g_stage.must_get()
}

pub fn clear(self : Stage) -> Unit {
  self.state = StageState::INACTIVE
  // self.chars.clear()
  self.npcs.clear()
  self.mobs.clear()
  self.drops.clear()
  // self.reactors.clear()
}

let g_stage : @utils.Singleton[Stage] = @utils.Singleton::new()

pub fn load(self : Stage, map_id : Int, portal_id : Int) -> Unit {
  match self.state {
    StageState::INACTIVE => {
      self.map_id = map_id
      let poll_fn = @map.load_map(map_id)
      self.state = StageState::TRANSITION(~portal_id, ~poll_fn)
    }
    StageState::TRANSITION(_) =>
      // TODO: respawn?
      @log.warn({ "map_id": map_id }, "map already loading")
    StageState::ACTIVE(_) => ()
  }
}

pub fn load_player(self : Stage, entry : @login.CharEntry) -> @player.Player! {
  let player = @player.Player::from_entry!(
    entry,
    self.inventory,
    self.damage_number_set,
  )
  self.player = Some(player)
  self.combat = Some(Combat::new(self.damage_number_set, player, self.mobs))
  self.start = now_micro() |> TimePoint::from_micro
  player
}

pub fn get_player(self : Stage) -> @player.Player? {
  self.player
}

pub fn get_npcs(self : Stage) -> MapNpcs {
  self.npcs
}

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

pub fn draw(self : Stage, alpha : Double) -> Unit {
  guard let StageState::ACTIVE(~tiles_objs, ~backgrounds, ~portals, ..) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(_) => return
  }
  let viewpos = self.camera.position_interpolated(alpha)
  let viewrpos = self.camera.real_position(alpha)
  let viewx = viewrpos.x
  let viewy = viewrpos.y
  backgrounds.drawbackgrounds(viewx, viewy, alpha)
  let player = self.player.unwrap()
  for id in @layer.ids {
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
  backgrounds.drawforegrounds(viewx, viewy, alpha)
  //     effect_.draw();
}

pub fn transfer_player() -> Unit {
  new_player_map_transfer_packet().dispatch()
}

fn update(self : Stage) -> Unit! { // Make sure to destructure map_info here
  guard let StageState::ACTIVE(
    ~tiles_objs,
    ~backgrounds,
    ~physics,
    ~portals,
    ~map_info,
    ..
  ) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(~portal_id, ~poll_fn) =>
      match poll_fn!() {
        Some(map_struct) => {
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
          return  // for simplicity, just wait for the next update
        }
        None => return ()
      }
  }
  self.combat.unwrap().update()
  backgrounds.update()
  // effect_.update();
  tiles_objs.update()

  // reactors_.update(self.physics);
  self.npcs.update(physics)
  self.mobs.update?(physics).unwrap()
  // chars_.update(self.physics);
  self.drops.update(physics)
  let player = self.player.unwrap()
  player.update(physics, map_info) |> ignore // Pass map_info here
  portals.update(player.get_position())
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
  guard let StageState::ACTIVE(~physics, ~map_info, ~portals, ..) = self.state else {
    StageState::INACTIVE => return
    StageState::TRANSITION(_) => return
  }
  match self.player {
    Some(player) =>
      match t {
        @KeyType.Id::ACTION => {
          if down {
            match @KeyAction.get_action_by_id?(action).unwrap() {
              @KeyAction.Id::UP =>
                self.check_portals(map_info, portals, physics)
              // @KeyAction.Id::SIT => self.check_seats()
              @KeyAction.Id::ATTACK => self.combat.unwrap().use_move!(0)
              @KeyAction.Id::PICKUP => self.check_drops()
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
  let playerpos = player.get_position()
  let warpinfo = portals.find_warp_at(playerpos)
  if warpinfo.intramap {
    let spawnpoint = portals.get_portal_by_name(warpinfo.toname)
    let startpos = physics.get_y_below(spawnpoint)
    player.respawn(startpos, map_info.is_underwater())
  } else if warpinfo.valid {
    new_change_map_packet(false, -1, warpinfo.name, false).dispatch()
    let stats = player.get_stats()
    stats.set_mapid(warpinfo.mapid)
  }

  // Sound(Sound::Name::PORTAL).play();
}

fn get_character(self : Stage, cid : Int) -> @character.Character? {
  match self.player {
    Some(player) => if player.get_oid() == cid { return Some(player) }
    None => ()
  }
  // TODO: chars
  None
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

struct ChangeStatsHandler {
  stage : Stage
}

fn ChangeStatsHandler::new(stage : Stage) -> ChangeStatsHandler {
  { stage, }
}

fn handle(self : ChangeStatsHandler, recv : @net.InPacket) -> Unit! {
  recv.read_bool!() |> ignore // 'itemreaction'
  let updatemask = recv.read_int!()
  let mut recalculate = false
  let player = self.stage.get_player().unwrap()
  for it in @MapleStat.codes {
    let (stat_id, stat_mask) = it
    if (updatemask & stat_mask) != 0 {
      recalculate = recalculate || self.handle_stat!(player, stat_id, recv)
    }
  }
  if recalculate {
    player.recalc_stats!(false)
  }
  UI::get().enable()
}

fn handle_stat(
  self : ChangeStatsHandler,
  player : @player.Player,
  stat : @MapleStat.Id,
  recv : @net.InPacket
) -> Bool! {
  let mut recalculate = false
  match stat {
    @MapleStat.Id::SKIN => player.change_look(stat, recv.read_short!())
    @MapleStat.Id::FACE | @MapleStat.Id::HAIR =>
      player.change_look(stat, recv.read_int!())
    @MapleStat.Id::LEVEL => player.change_level(recv.read_ubyte!())
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
    @MapleStat.Id::EXP =>
      player.get_stats().set_exp(recv.read_int!().to_int64())
    @MapleStat.Id::MESO => self.stage.inventory.set_meso(recv.read_int!())
    _ => {
      player.get_stats().set_stat(stat, recv.read_short!())
      recalculate = true
    }
  }
  // let update_statsinfo = need_statsinfo_update(stat)

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

pub fn get_mobs(self : Stage) -> @monster.MapMobs {
  self.mobs
}

pub fn get_inventory(self : Stage) -> @inventory.Inventory {
  self.inventory
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

fn check_drops(self : Stage) -> Unit {
  let playerpos = self.player.unwrap().get_position()
  match self.drops.find_loot_at(playerpos) {
    Some((drop_oid, drop_pos)) =>
      new_pickup_item_packet(drop_oid, drop_pos).dispatch()
    None => ()
  }
}

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
