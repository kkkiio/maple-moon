///|
using @maple_protocol {type SetFieldMessage, type StatsEntry}

///|
pub(all) struct Stage {
  // camera : Camera
  map_portals_animations : @map.MapPortalAnimations
  // npcs : @npc.MapNpcs
  // quests : @quest.MapQuests
  mobs : @monster.MapMobs
  // drops : @drop.MapDrops
  // inventory : @inventory.Inventory
  // damage_number_set : @ui.NumberSet
  // combat : @combat_impl.Combat
  // char_look_module : @char_look.Module
  // skill_book_module : @skill_book.Module
  // char_stats_module : @char_stats.Module
  // network : @net.Network
  map_change_listeners : Array[(@map.SceneMap) -> Bool]
  // bullet_module : @bullet.Module
}

///|
pub fn Stage::new(
  map_portals_animations : @map.MapPortalAnimations,
  mobs : @monster.MapMobs,
  // drops : @drop.MapDrops,
  // inventory : @inventory.Inventory,
  // npcs : @npc.MapNpcs,
  // quests : @quest.MapQuests,
  // char_look_module : @char_look.Module,
  // skill_book_module : @skill_book.Module,
  // char_stats_module : @char_stats.Module,
  // damage_number_set : @ui.NumberSet,
  // network : @net.Network,
  // bullet_module : @bullet.Module,
  // combat : @combat_impl.Combat,
) -> Stage {
  {
    map_portals_animations,
    // camera: Camera::new(),
    // npcs,
    // quests,
    // damage_number_set,
    // combat,
    mobs,
    // drops,
    // inventory,
    // char_look_module,
    // skill_book_module,
    // char_stats_module,
    // network,
    map_change_listeners: Array::new(),
  }
  // bullet_module,
}

///|
fn Stage::clear(self : Stage) -> Unit {
  // self.state = StageState::INACTIVE
  // self.chars.clear()
  // self.npcs.clear()
  // self.quests.clear()
  self.mobs.clear()
  // self.drops.clear()
  // self.reactors.clear()
}

///|
fn respawn_player(
  player : @player.Player,
  portal_id : Int,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics,
) -> Unit {
  // TODO: Music
  guard portals.get_portal_pos_by_id(portal_id) is Some(spawn_point) else {
    @log.fatal("portal not found", data={ "portal_id": portal_id })
  }
  let startpos = physics.get_y_below(spawn_point)
  let left = map_info.get_walls().first().to_double()
  let right = map_info.get_walls().second().to_double()
  let top = map_info.get_borders().first().to_double()
  let bottom = map_info.get_borders().second().to_double()
  @log.info("respawn", data={
    "spawn_point": spawn_point,
    "portal_id": portal_id,
    "startpos": startpos,
    "left": left,
    "right": right,
    "top": top,
    "bottom": bottom,
  })
  player.respawn(startpos, map_info.is_underwater())
  @camera.attach_entity(player.entity, @selene_math.Vec2D(16.0, 16.0))
  let (left, right, top, bottom) = normalize_camera_limits(
    left, right, top, bottom,
  )
  @camera.set_limits(left~, right~, top~, bottom~)
}

///|
fn normalize_camera_limits(
  left : Double,
  right : Double,
  top : Double,
  bottom : Double,
) -> (Double, Double, Double, Double) {
  let viewport_width = @graphics.view_size.0.to_double()
  let viewport_height = @graphics.view_size.1.to_double()
  let right = if right - left < viewport_width {
    left + viewport_width
  } else {
    right
  }
  let top = if bottom - top < viewport_height {
    bottom - viewport_height
  } else {
    top
  }
  (left, right, top, bottom)
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
  // // effect_.update();
  // tiles_objs.update()

  // // reactors_.update(self.physics);
  // self.npcs.update(physics)
  // self.quests.update(physics)
  // self.mobs.update(physics, self.network)
  // // chars_.update(self.physics);
  // self.drops.update(physics)
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
pub fn reset_player_position() -> Unit {
  guard @game_state.game_state.phase
    is @game_state.GamePhase::GameActive(
      portals~,
      map_info~,
      portal_id~,
      physics~,
      ..
    ) else {
    return
  }
  guard @player.get_player() is Some(player) else { return }
  respawn_player(player, portal_id, map_info, portals, physics)
}

///|
let stage_ref : Ref[Stage?] = Ref::new(None)

///|
pub fn get_stage() -> Stage? {
  stage_ref.val
}

///|
pub fn scene_transition_system(_delta : Double) -> Unit {
  match @game_state.game_state.phase {
    SelectCharacter => {
      stage_ref.val = None
      return
    }
    GameStart(map_id~, portal_id~, set_field_message~) => {
      guard set_field_message is SetField(stats~, inventory_entry~, ..) else {
        return
      }
      // 1. 如果没有开始加载数据，启动后台任务加载默认武器、头发和脸
      guard get_loading_data() is Some(fut) else {
        guard @char_look.get_module() is Some(char_look_mod) else { return }
        let draw_info = char_look_mod.draw_info
        let weapon_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::WEAPON,
        ).unwrap_or(1302000)
        let top_id = find_equipped_item_id(inventory_entry.items, @slot.Id::TOP).unwrap_or(
          1040002,
        )
        let bottom_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::BOTTOM,
        ).unwrap_or(1060002)
        let shoes_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::SHOES,
        ).unwrap_or(1072005)
        set_loading_data(
          @io_service.submit_background_task(async fn() {
            let hair = @char_look.Hair::load(30000, draw_info)
            let face = @char_look.Face::load(20000)
            let weapon_data = @item.ItemData::get_async(weapon_id)
            let top_data = @item.ItemData::get_async(top_id)
            let bottom_data = @item.ItemData::get_async(bottom_id)
            let shoes_data = @item.ItemData::get_async(shoes_id)
            let after_image_name = if weapon_data.get_info()
              is { "afterImage": Json::String(after_image), .. } {
              after_image
            } else {
              "swordOL"
            }
            let after_image_res = @resource.get_afterimage_loader()
              .load_res_async(["\{after_image_name}.img"])
              .value()
            let after_images = @json.from_json(after_image_res)
            @char_look.set_after_images(after_image_name, after_images)
            // Load and register skills
            let sk = @combat_impl.load_skill_move(
              @skill.SkillId::TELEPORT_FP.int_value(),
              bullet_module,
            )
            @combat_impl.register_move(sk)
            (weapon_data, top_data, bottom_data, shoes_data, hair, face)
          }),
        )
        return
      }

      // 2. 轮询 Future，如果没有完成则直接返回（等待下一帧）
      guard fut.poll() is Some(res) else { return }

      // 3. 数据加载完成，处理结果
      let (weapon_data, top_data, bottom_data, shoes_data, hair, face) = match
        res {
        Ok(data) => data
        Err(e) => {
          @log.error("fail to load game start data", data={ "error": e })
          panic()
        }
      }

      // 4. 创建 Character Look 并装备武器
      let char_look = try {
        guard @char_look.get_module() is Some(char_look_mod) else { return }
        let draw_info = char_look_mod.draw_info
        let stance_bodys_map = char_look_mod.stance_bodys_map.0
        let stance_heads_map = char_look_mod.stance_heads_map.0
        let entity = @entity.Entity::new()
        let look = @char_look.CharLook::new(
          entity,
          {},
          @char_look.FullBody::new(
            0, draw_info, stance_bodys_map, stance_heads_map,
          ),
          hair,
          face,
          draw_info,
        )
        // 装备加载好的武器和初始装备
        look.add_equip(weapon_data, @slot.Id::WEAPON)
        look.add_equip(top_data, @slot.Id::TOP)
        look.add_equip(bottom_data, @slot.Id::BOTTOM)
        look.add_equip(shoes_data, @slot.Id::SHOES)
        look
      } catch {
        e => @log.fatal("fail to load char look", data={ "error": e })
      }

      // 5. 初始化 Stage 并切换到 GameTransiting 状态
      let stage = match stage_ref.val {
        Some(stage) => stage
        None => {
          let stage = new_stage(char_look, stats)
          stage_ref.val = Some(stage)
          stage
        }
      }
      match @player.get_player() {
        Some(player) =>
          apply_equipped_stats(player.get_stats(), inventory_entry.items)
        None => ()
      }
      clear_loading_data()
      stage.clear()
      @game_state.game_state.phase = @game_state.GamePhase::GameTransiting(
        map_id~,
        portal_id~,
        loading_map=None,
      )
    }
    GameTransiting(map_id~, portal_id~, loading_map~) as t => {
      let stage = stage_ref.val.unwrap()
      guard loading_map is Some(fut) else {
        t.loading_map = Some(
          @io_service.submit_background_task(fn() {
            let map_resources = @map.load_map_resources_by_id(map_id)
            @map.create_scene_map(map_resources, stage.map_portals_animations)
          }),
        )
        return
      }
      guard fut.poll() is Some(res) else { return }
      let sence_map = match res {
        Ok(sence_map) => sence_map
        Err(e) => {
          @log.error("fail to load map", data={ "error": e, "map_id": map_id })
          panic()
        }
      }
      @game_state.game_state.phase = @game_state.GamePhase::GameActive(
        map_id~,
        portal_id~,
        tiles_objs=sence_map.tiles_objs,
        backgrounds=sence_map.backgrounds,
        physics=sence_map.physics,
        map_info=sence_map.map_info,
        portals=sence_map.portals,
        mobs=stage.mobs,
      )
      // 设置怪物上下文，让怪物生成消息能被正确处理
      @monster.set_mobs({ map_mobs: stage.mobs, physics: sence_map.physics })
      @game_server.send(@maple_protocol.PlayerMapTransferMessage::default())
      let player = @player.get_player().unwrap()
      let combat = @combat_impl.Combat::new(stage.mobs, bullet_module)
      @combat_impl.set_combat(Some(combat))
      @combat_impl.set_player(Some(player))
      // let width = sence_map.map_info.get_walls().delta()
      // let height = sence_map.map_info.get_borders().delta()
      @map.set_backgrounds(sence_map.backgrounds)
      @map.set_tiles_objs(sence_map.tiles_objs)
      @map.set_portals(sence_map.portals, get_touch_pos=fn() {
        @player.get_player().map(fn(player) { player.character.get_position() })
      })
      respawn_player(
        player,
        portal_id,
        sence_map.map_info,
        sence_map.portals,
        sence_map.physics,
      )
      stage.map_change_listeners.retain(fn(listener) { listener(sence_map) })
      return
    }
    @game_state.GamePhase::GameActive(..) => ()
  }
}

///|
fn new_stage(
  char_look : @char_look.CharLook,
  stats_entry : StatsEntry,
) -> Stage {
  let map_module = @map.Module::load()
  let stats : @char_stats.CharStats = @char_stats.CharStats::new(
    stats_entry,
    fn() {
      char_look
      .get_equips()
      .get_weapon()
      .map(fn(w) { w.get_type() })
      .unwrap_or(@weapon.Type::NONE)
    },
    make_job_from_stats(stats_entry),
    Map::new(),
    Map::new(),
    Map::new(),
  )
  let entity = char_look.get_root_entity()
  entity.respawn()
  let player : @player.Player = @player.Player::new(
    entity, 1, "kkkiio", char_look, stats,
  )
  @player.set_player(player)
  // TODO: reset cooldowns
  // self.combat.set_cooldowns(cooldowns)
  let monster_module = @monster.Module::new()
  let stage = Stage::new(
    map_module.get_portals_animations(),
    monster_module.get_map_mobs(),
  )
  stage_ref.val = Some(stage)
  stage
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "set_field",
    @net.Opcode::SET_FIELD.int_value(),
    fn(json : Json) -> Unit raise {
      let set_field_message : SetFieldMessage = @json.from_json(json)
      guard set_field_message is ChangeMap(map_id~, portal_id~) else { return }
      @game_state.game_state.phase = @game_state.GamePhase::GameTransiting(
        map_id~,
        portal_id~,
        loading_map=None,
      )
    },
  )
}

///|
let bullet_module : @bullet.Module = @bullet.Module::new({}) // TODO: load bullet data
