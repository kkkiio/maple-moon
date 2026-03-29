///|
using @server_proto {type SetFieldMessage, type StatsEntry}

///|
pub(all) struct Stage {
  // camera : Camera
  map_portals_animations : @map.MapPortalAnimations
  npcs : @npc.MapNpcs
  // quests : @quest.MapQuests
  mobs : @monster.MapMobs
  // drops : @drop.MapDrops
  // inventory : @inventory.Inventory
  // damage_number_set : @ui.NumberSet
  // combat : @combat_system.Combat
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
  npcs : @npc.MapNpcs,
  mobs : @monster.MapMobs,
  // drops : @drop.MapDrops,
  // inventory : @inventory.Inventory,
  // quests : @quest.MapQuests,
  // char_look_module : @char_look.Module,
  // skill_book_module : @skill_book.Module,
  // char_stats_module : @char_stats.Module,
  // damage_number_set : @ui.NumberSet,
  // network : @net.Network,
  // bullet_module : @bullet.Module,
  // combat : @combat_system.Combat
) -> Stage {
  {
    map_portals_animations,
    // camera: Camera::new(),
    npcs,
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
fn respawn_player(
  player : @player.Player,
  portal_id : Int,
  map_info : @map.MapInfo,
  portals : @map.MapPortals,
  physics : @physics.Physics,
) -> Unit {
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
  ignore(@ms_camera.ensure_camera_entity())
  @ms_camera.set_follow_target(
    player.entity,
    offset=@selene_math.Vec2D(16.0, 16.0),
  )
  let (left, right, top, bottom) = normalize_camera_limits(
    left, right, top, bottom,
  )
  @ms_camera.set_limits(left, right, top, bottom)
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
fn default_keymap() -> @keymap.Keymap {
  Map::from_array([
    (
      @inputs.Code::ArrowUp,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_UP),
    ),
    (
      @inputs.Code::ArrowDown,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_DOWN),
    ),
    (
      @inputs.Code::ArrowLeft,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_LEFT),
    ),
    (
      @inputs.Code::ArrowRight,
      @keymap.Action::BASIC(@keymap.BasicActionId::MOVE_RIGHT),
    ),
    (@inputs.Code::Space, @keymap.Action::BASIC(@keymap.BasicActionId::JUMP)),
    (@inputs.Code::KeyX, @keymap.Action::BASIC(@keymap.BasicActionId::ATTACK)),
    (@inputs.Code::KeyZ, @keymap.Action::BASIC(@keymap.BasicActionId::PICKUP)),
    // (@inputs.Code::KeyA, @keymap.Action::SKILL(1001004)), // Power Strike
    (
      @inputs.Code::KeyA,
      @keymap.Action::SKILL(@skill.SkillId::ARROW_BOMB_BOW.int_value()),
    ), // 
    (@inputs.Code::KeyF, @keymap.Action::SKILL(2101002)), // Teleport (F/P)
  ])
}

///|
pub fn Stage::get_mobs(self : Stage) -> @monster.MapMobs {
  self.mobs
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
  guard @game_state.current_phase()
    is @game_state.GamePhase::GameActive(portal_id~, ..) else {
    return
  }
  guard get_active_scene_map() is Some(scene_map) else { return }
  guard @player.get_player() is Some(player) else { return }
  respawn_player(
    player,
    portal_id,
    scene_map.map_info,
    scene_map.portals,
    scene_map.physics,
  )
}

///|
let stage_ref : Ref[Stage?] = Ref::new(None)

///|
let transiting_loading_ref : Ref[@utils.Future[Result[@map.SceneMap, Error]]?] = Ref::new(
  None,
)

///|
pub fn get_stage() -> Stage? {
  stage_ref.val
}

///|

///|
pub fn scene_transition_system(_world : @ecs.World) -> Unit {
  match @game_state.current_phase() {
    @game_state.GamePhase::GameSetup => ()
    @game_state.GamePhase::SelectCharacter
    | @game_state.GamePhase::ExplorerCharacterCreation => {
      stage_ref.val = None
      @bgm.clear_bgm()
      clear_active_scene_map()
      @map.clear_runtime_context()
      @npc.clear_map_npcs()
      @character.clear_character_registry()
      @mini_map_ui.clear_current_map()
      return
    }
    @game_state.GamePhase::GameStart(map_id~, portal_id~, set_field_message~) => {
      guard set_field_message is SetField(stats~, inventory_entry~, quests~, ..) else {
        return
      }
      if get_loading_data() is None {
        @keymap.set_keymap(default_keymap())
      }
      let player_item_ids = collect_inventory_item_ids(inventory_entry.items)
      let item_data_system = @item.get_item_data_system()
      item_data_system.request_consume_and_etc_preload()
      item_data_system.request_many(player_item_ids)

      if not(item_data_system.consume_and_etc_preload_ready_or_fail()) {
        return
      }
      if not(item_data_system.all_requested_ready_or_fail(player_item_ids)) {
        return
      }

      // 1. 如果没有开始加载数据，启动后台任务加载开局资源
      guard get_loading_data() is Some(fut) else {
        guard @char_look.get_resource() is Some(char_presentation_resource) else {
          return
        }
        let draw_info = char_presentation_resource.draw_info
        let weapon_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::WEAPON,
        )
        let top_id = find_equipped_item_id(inventory_entry.items, @slot.Id::TOP)
        let bottom_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::BOTTOM,
        )
        let shoes_id = find_equipped_item_id(
          inventory_entry.items,
          @slot.Id::SHOES,
        )
        @log.info("set_field_equipped_snapshot", data={
          "weapon_id": weapon_id.to_json(),
          "top_id": top_id.to_json(),
          "bottom_id": bottom_id.to_json(),
          "shoes_id": shoes_id.to_json(),
          "inventory_item_count": inventory_entry.items.length().to_json(),
        })
        set_loading_data(
          @io_service.submit_background_task(async fn() {
            let hair = @char_look.Hair::load(30000, draw_info)
            let face = @char_look.Face::load(20000)
            let weapon_data = match weapon_id {
              Some(id) => Some(@item.request_item_data(id))
              None => None
            }
            let top_data = match top_id {
              Some(id) => Some(@item.request_item_data(id))
              None => None
            }
            let bottom_data = match bottom_id {
              Some(id) => Some(@item.request_item_data(id))
              None => None
            }
            let shoes_data = match shoes_id {
              Some(id) => Some(@item.request_item_data(id))
              None => None
            }
            let after_image_name = match weapon_data {
              Some(w_data) =>
                match w_data.get_info() {
                  { "afterImage": Json::String(after_image), .. } =>
                    Some(after_image)
                  _ => {
                    @log.fatal("weapon missing afterImage", data={
                      "item_id": weapon_id.unwrap_or(0),
                    })
                    panic()
                  }
                }
              None => None
            }
            match after_image_name {
              Some(after_image_name) => {
                let after_image_res = @resource.require_async_loader(
                  "afterimage",
                ).load_resource(["\{after_image_name}.img"])
                let after_images = @json.from_json(after_image_res)
                @char_look.set_after_images(after_image_name, after_images)
              }
              None => ()
            }
            let bullet_module = @bullet.Module::load()
            @bullet.set_bullet_module(bullet_module)
            // Load and register skills (optional - missing skills log warning only)
            let skill_ids = [
              @skill.SkillId::TELEPORT_FP.int_value(),
              @skill.SkillId::POWER_STRIKE.int_value(),
              @skill.SkillId::ARROW_BOMB_BOW.int_value(),
              // Final attack passives
              @skill.SkillId::SWORD_FA_FIGHTER.int_value(),
              @skill.SkillId::AXE_FA.int_value(),
            ]
            for skill_id in skill_ids {
              let sk = @skill_cast.load_skill_move(skill_id)
              @skill_cast.register_move(sk)
            }
            @markup_text.preload_reference_data()
            if not(@markup_text.is_reference_data_ready()) {
              @log.fatal("markup_text reference data is not ready")
              panic()
            }
            let npc_loader = @resource.require_async_loader("npc")
            let string_loader = @resource.require_async_loader("string")
            (
              weapon_data, top_data, bottom_data, shoes_data, hair, face, npc_loader,
              string_loader,
            )
          }),
        )
        return
      }

      // 2. 轮询 Future，如果没有完成则直接返回（等待下一帧）
      guard fut.poll() is Some(res) else { return }

      // 3. 数据加载完成，处理结果
      let (
        weapon_data,
        top_data,
        bottom_data,
        shoes_data,
        hair,
        face,
        npc_loader,
        string_loader,
      ) = match res {
        Ok(data) => data
        Err(e) => {
          @log.error("fail to load game start data", data={ "error": e })
          panic()
        }
      }

      // 4. 创建 Character Look 并装备武器
      let char_look = try {
        guard @char_look.get_resource() is Some(char_presentation_resource) else {
          return
        }
        let draw_info = char_presentation_resource.draw_info
        let stance_bodys_map = char_presentation_resource.stance_bodys_map.0
        let stance_heads_map = char_presentation_resource.stance_heads_map.0
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
        match weapon_data {
          Some(data) => look.add_equip(data, @slot.Id::WEAPON)
          None => ()
        }
        match top_data {
          Some(data) => look.add_equip(data, @slot.Id::TOP)
          None => ()
        }
        match bottom_data {
          Some(data) => look.add_equip(data, @slot.Id::BOTTOM)
          None => ()
        }
        match shoes_data {
          Some(data) => look.add_equip(data, @slot.Id::SHOES)
          None => ()
        }
        look
      } catch {
        e => @log.fatal("fail to load char look", data={ "error": e })
      }

      // 5. 初始化 Stage 并切换到 GameTransiting 状态
      match stage_ref.val {
        Some(_) => ()
        None => ignore(new_stage(char_look, stats, npc_loader, string_loader))
      }
      @item_use_events.clear_intents()
      @quest_log.handle_player_quest_info(quests)
      match @player.get_player() {
        Some(player) => {
          apply_equipped_stats(player.get_stats(), inventory_entry.items)
          @quest_icon.bind_player(player)
        }
        None => ()
      }
      clear_loading_data()
      let global_inv = @inventory.inventory.val
      global_inv.clear()
      global_inv.set_meso(inventory_entry.meso)
      for kind, slotmax in inventory_entry.slot_maxs.0 {
        global_inv.set_slotmax(kind, slotmax)
      }
      for item in inventory_entry.items {
        @inventory.handle_item(global_inv, item)
      }
      match @player.get_player() {
        Some(player) =>
          global_inv.recalc_stats(player.character.get_weapontype())
        None => ()
      }
      @inventory_ui.bind_inventory(global_inv)
      clear_active_scene_map()
      @map.clear_runtime_context()
      @npc.clear_map_npcs()
      transiting_loading_ref.val = None
      @game_state.set_next_phase(
        @game_state.GamePhase::GameTransiting(map_id~, portal_id~),
      )
    }
    @game_state.GamePhase::GameTransiting(map_id~, portal_id~) => {
      let stage = stage_ref.val.unwrap()
      guard transiting_loading_ref.val is Some(fut) else {
        transiting_loading_ref.val = Some(
          @io_service.submit_background_task(async fn() {
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
      set_active_scene_map(sence_map)
      @map.set_runtime_context(sence_map.map_info, sence_map.physics)
      transiting_loading_ref.val = None
      @game_state.set_next_phase(
        @game_state.GamePhase::GameActive(map_id~, portal_id~),
      )
      // 设置怪物上下文，让怪物生成消息能被正确处理
      @npc.set_npcs({ map_npcs: stage.npcs, physics: sence_map.physics })
      @monster.set_mobs({ map_mobs: stage.mobs, physics: sence_map.physics })
      @drop.set_map_physics(sence_map.physics)
      @game_server.send(@server_proto.PlayerMapTransferMessage::default())
      let player = @player.get_player().unwrap()
      let bullet_system = @bullet.BulletSystem::new()
      let combat = @combat_system.Combat::new(stage.mobs)
      @combat_system.set_combat(Some(combat))
      @bullet.set_current_bullet_system(Some(bullet_system))
      @combat_system.set_player(Some(player))
      // Register passive skills
      @passive.register_passive_skill(@passive.sword_fa_fighter_passive)
      // let width = sence_map.map_info.get_walls().delta()
      // let height = sence_map.map_info.get_borders().delta()
      @map.set_backgrounds(sence_map.backgrounds)
      @map.set_tiles_objs(sence_map.tiles_objs)
      @map.set_portals(sence_map.portals, get_touch_pos=fn() {
        @player.get_player().map(fn(player) { player.character.get_position() })
      })
      @bgm.sync_map_bgm(sence_map.map_info.get_bgm())
      respawn_player(
        player,
        portal_id,
        sence_map.map_info,
        sence_map.portals,
        sence_map.physics,
      )
      stage.map_change_listeners.retain(fn(listener) { listener(sence_map) })
      @mini_map_ui.set_current_map(
        sence_map.id,
        sence_map.map_info.map_name,
        sence_map.map_info.street_name,
        sence_map.mini_map_resources,
      )
      @world_map_ui.set_current_map(
        sence_map.id,
        sence_map.map_info.map_name,
        sence_map.map_info.street_name,
      )
      return
    }
    @game_state.GamePhase::GameActive(..) => ()
  }
}

///|
fn new_stage(
  char_look : @char_look.CharLook,
  stats_entry : StatsEntry,
  npc_loader : @resource.AsyncLoader,
  string_loader : @resource.AsyncLoader,
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
  let global_inv = @inventory.inventory.val
  entity.respawn()
  let player : @player.Player = @player.Player::new(
    entity, 1, "kkkiio", global_inv, char_look, stats,
  )
  @player.set_player(player)
  @character.register_character(player.get_character())
  // TODO: reset cooldowns
  // self.combat.set_cooldowns(cooldowns)
  let map_npcs = @npc.MapNpcs::new(
    @npc_talk_ui.open_npc_talk_ui,
    @npc_talk_ui.is_npc_talk_ui_open,
    npc_loader~,
    string_loader~,
  )
  let monster_module = @monster.Module::new()
  let stage = Stage::new(
    map_module.get_portals_animations(),
    map_npcs,
    monster_module.get_map_mobs(),
  )
  stage_ref.val = Some(stage)
  stage
}

///|
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "set_field",
    @server_proto.Opcode::SET_FIELD.int_value(),
    fn(json : Json) -> Unit raise {
      let set_field_message : SetFieldMessage = @json.from_json(json)
      guard set_field_message is ChangeMap(map_id~, portal_id~) else { return }
      @item_use_events.clear_intents()
      clear_active_scene_map()
      @map.clear_runtime_context()
      @npc.clear_map_npcs()
      @character.clear_character_registry()
      transiting_loading_ref.val = None
      @game_state.set_next_phase(
        @game_state.GamePhase::GameTransiting(map_id~, portal_id~),
      )
    },
  )
}
