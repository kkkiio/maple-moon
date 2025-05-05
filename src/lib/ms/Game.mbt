///|
typealias UI = @ui.UI

///|
pub(all) struct Game {
  window : Window
  timer : @utils.Timer
  mut accumulator : Int
  ui : UI
  processor : @net.Network
  loaded_state : @utils.Future[LoadedState]
  io_service : @io_task.Service
  scheduls : @schedule.Schedules
  stage : Ref[Stage?]
  keyboard_module : @keyboard.Module
}

///|
struct LoadedState {
  login_module : @login.Module
  inventory_module : @inventory.Module
  skill_book_module : @skill_book.Module
  char_stats_module : @char_stats.Module
  shop_module : @shop.Module
}

///|
pub fn Game::new() -> Game {
  @config.global().set_hardware_info()
  let timer = @utils.Timer::new(fn() {
    now_micro() |> @utils.TimePoint::from_micro
  })
  let processor = @net.Network::init()
  let keyboard_module = @keyboard.Module::new(default_keymap(), processor)
  let keyboard = keyboard_module.get_keyboard()
  let ui = UI::new(fn(keycode) { keyboard.get_mapping(keycode) })
  let window = Window::new(ui, fn() {
    now_micro() |> @utils.TimePoint::from_micro
  })
  let io_service = @io_task.Service::new()
  let scheduls = @schedule.Schedules::new()
  let stage = Ref::new(None)
  {
    window,
    timer,
    accumulator: 0,
    ui,
    processor,
    loaded_state: load_modules(
      ui, timer, processor, io_service, scheduls, stage, keyboard_module,
    ),
    io_service,
    scheduls,
    stage,
    keyboard_module,
  }
}

///|
fn load_modules(
  ui : UI,
  timer : @utils.Timer,
  network : @net.Network,
  io_service : @io_task.Service,
  scheduls : @schedule.Schedules,
  stage_ref : Ref[Stage?],
  keyboard_module : @keyboard.Module
) -> @utils.Future[LoadedState] {
  fn get_stage() -> Stage {
    stage_ref.val.unwrap() // TODO: handle error
  }

  let add_io_task = fn(task) { io_service.add(task) }
  let action_registry = @action.Registry::new()
  let action_map = {}
  fn merge_actions(
    map : Map[@keyboard.BasicActionId, @action.Descriptor]
  ) -> Unit {
    for id, descriptor in map {
      action_map.set(id, descriptor)
    }
  }

  let net_handler_map = {}
  fn merge_handlers(
    handlers : Map[@net.Opcode, (@net.InPacket) -> Unit]
  ) -> Unit {
    for opcode, handler in handlers {
      net_handler_map.set(opcode, handler)
    }
  }

  merge_handlers(keyboard_module.make_handlers())
  let stat_handler_map = {}
  fn merge_stat_handlers(
    handlers : Map[@maple_stat.Id, @game_mod.StatHandler]
  ) {
    for stat_id, handler in handlers {
      if stat_handler_map.contains(stat_id) {
        @log.error({ "stat": stat_id }, "duplicate stat handler")
        panic()
      } else {
        stat_handler_map.set(stat_id, handler)
      }
    }
  }

  let char_look_module_f = @char_look.Module::load(
    fn(f) {
      guard get_stage().get_player() is Some(player) else { return }
      player.character.look = f(player.character.look)
    },
    io_service,
  ).tap(fn(mod) { merge_stat_handlers(mod.make_stat_handlers()) })
  let map_module = @map.Module::load()
  let inventory_module_fut = @inventory.Module::load(
    fn() { get_stage().get_player() },
    network,
  ).tap(fn(mod) {
    merge_handlers(mod.make_handlers())
    merge_actions(mod.make_actions())
    merge_stat_handlers(mod.make_stat_handlers())
  })
  let login_mod_f = char_look_module_f
    .bind(fn(mod) { @login.Module::load(network, ui, mod, io_service) })
    .combine(inventory_module_fut)
    .combine(map_module)
    .map(fn(it) {
      let ((login_module, inventory_module), map_module) = it
      merge_handlers(
        login_module.make_handlers(
          fn(map_id, portal_id) { get_stage().transition(map_id, portal_id) },
          fn(char_entry, callback) {
            get_stage().set_player_stage(char_entry, callback)
          },
          inventory_module.get_inventory(),
          fn(player) {
            setup_game_ui(
              ui,
              get_stage(),
              player,
              action_registry,
              timer,
              map_module,
            )
          },
        ),
      )
      login_module
    })
  let monster_module = @monster.Module::new(add_io_task)
  merge_handlers(
    monster_module.make_handlers(fn() {
      get_stage().get_player().map(fn(p) { p.get_stats() })
    }),
  )
  let drop_module = @drop.Module::load().tap(fn(mod) {
    merge_handlers(
      mod.make_handlers(fn(id) {
        get_stage().get_character(id).map(fn(c) { c.get_phobj() })
      }),
    )
  })
  let npc_module = @npc.Module::load(
    ui,
    fn() { get_stage().get_player().unwrap().character.get_name() },
    network,
  ).tap(fn(mod) { merge_handlers(mod.make_handlers()) })
  let char_stats_mod_f = @char_stats.Module::load(network).tap(fn(mod) {
    merge_stat_handlers(mod.make_stat_handlers())
  })
  let skill_book_mod_f = @skill_book.Module::load(
    fn() { get_stage().get_player() },
    network,
  ).tap(fn(mod) {
    merge_handlers(mod.make_handlers())
    merge_actions(mod.make_actions())
  })
  let shop_mod_f = @shop.Module::load(network).map(fn(it) {
    let mod = it
    merge_handlers(mod.make_handlers())
    mod
  })
  // // Attack handlers
  // // packet_switch.push((ATTACKED_CLOSE, CloseAttackHandler::new()))
  // // packet_switch.push((ATTACKED_RANGED, RangedAttackHandler::new()))
  // // packet_switch.push((ATTACKED_MAGIC, MagicAttackHandler::new()))

  // // Messaging handlers
  // // packet_switch.push((SHOW_STATUS_INFO, ShowStatusInfoHandler::new()))
  // // packet_switch.push((CHAT_RECEIVED, ChatReceivedHandler::new()))
  // // packet_switch.push((SCROLL_RESULT, ScrollResultHandler::new()))
  // // packet_switch.push((SERVER_MESSAGE, ServerMessageHandler::new()))
  // // packet_switch.push((WEEK_EVENT_MESSAGE, WeekEventMessageHandler::new()))
  // // packet_switch.push((WHISPER, WhisperReceivedHandler::new()))
  // // packet_switch.push((SHOW_ITEM_GAIN_INCHAT, ShowItemGainInChatHandler::new()))

  // // Inventory Handlers
  // // packet_switch.push((GATHER_RESULT, GatherResultHandler::new()))
  // // packet_switch.push((SORT_RESULT, SortResultHandler::new()))

  // // Player Interaction
  // // packet_switch.push((CHAR_INFO, CharInfoHandler::new()))
  // // packet_switch.push((PLAYER_INTERACTION, PlayerInteractionHandler::new()))

  // // Cash Shop
  // // packet_switch.push((SET_CASH_SHOP, SetCashShopHandler::new()))

  // // TODO: New handlers, they need coded and moved to a proper file.
  // // packet_switch.push((CHECK_SPW_RESULT, CheckSpwResultHandler::new()))
  // // packet_switch.push((FIELD_EFFECT, FieldEffectHandler::new()))

  //  )
  // Player handlers
  // packet_switch.push((CHANGE_CHANNEL, ChangeChannelHandler::new()))
  // packet_switch.push((KEYMAP, KeymapHandler::new()))
  // packet_switch.push((SKILL_MACROS, SkillMacrosHandler::new()))
  let change_stat_handler = make_change_stats_handler(stat_handler_map, fn() {
    guard get_stage().get_player() is Some(player) else { return }
    player.recalc_stats(false)
  })
  net_handler_map.set(change_stat_handler.0, change_stat_handler.1)
  let job_module = @job.Module::new(fn(job_id) {
    guard get_stage().get_player() is Some(player) else { return }
    player.change_job(job_id)
  })
  merge_stat_handlers(job_module.make_stat_handlers())

  // MapObject handlers
  // // packet_switch.push((SPAWN_CHAR, SpawnCharHandler::new()))
  // // packet_switch.push((CHAR_MOVED, CharMovedHandler::new()))
  // // packet_switch.push((UPDATE_CHARLOOK, UpdateCharLookHandler::new()))
  // // packet_switch.push((SHOW_FOREIGN_EFFECT, ShowForeignEffectHandler::new()))
  // // packet_switch.push((GIVE_FOREIGN_BUFF, GiveForeignBuffHandler::new()))
  // // packet_switch.push((CANCEL_FOREIGN_BUFF, CancelForeignBuffHandler::new()))
  // // packet_switch.push((REMOVE_CHAR, RemoveCharHandler::new()))
  // // packet_switch.push((SPAWN_PET, SpawnPetHandler::new()))
  // |> Iter::append((SET_NPC_SCRIPTABLE, SetNpcScriptableHandler::new()))
  // // packet_switch.push((MOB_MOVED, MobMovedHandler::new()))
  // // packet_switch.push((MOB_MOVE_RESPONSE, MobMoveResponseHandler::new()))
  // // packet_switch.push((APPLY_MONSTER_STATUS, ApplyMobStatusHandler::new()))
  // // packet_switch.push((CANCEL_MONSTER_STATUS, CancelMobStatusHandler::new()))
  // // packet_switch.push((HIT_REACTOR, HitReactorHandler::new()))
  // // packet_switch.push((SPAWN_REACTOR, SpawnReactorHandler::new()))
  // // packet_switch.push((REMOVE_REACTOR, RemoveReactorHandler::new()))
  // packet_switch.push((GIVE_BUFF, ApplyBuffHandler::new()))
  // packet_switch.push((CANCEL_BUFF, CancelBuffHandler::new()))
  net_handler_map.set(@net.RECALCULATE_STATS, fn(
    _recv : @net.InPacket
  ) -> Unit {
    guard get_stage().get_player() is Some(player) else { return }
    player.recalc_stats(false)
  })
  let loading_mods = [
    @utils.Future::from_value(
      @heal_over_time.new_module(scheduls, network, fn() {
        get_stage().get_player().map(fn(p) { p.get_stats() })
      }),
    ),
  ]
  // packet_switch.push((FAME_RESPONSE, FameResponseHandler::new()))
  // packet_switch.push((ADD_COOLDOWN, AddCooldownHandler::new()))
  // NPC Interaction Handlers
  let damage_number_set = @ui.NumberSet::load()
  let stage_f = map_module
    .combine(inventory_module_fut)
    .combine(npc_module)
    .combine(char_look_module_f)
    .combine(char_stats_mod_f)
    .combine(skill_book_mod_f)
    .combine(drop_module)
    .combine(damage_number_set)
    .combine(@utils.Future::all_of(loading_mods))
    .map(fn(it) {
      let (
        (
          (
            (
              (
                (((map_module, inventory_module), npc_module), char_look_module),
                char_stats_mod,
              ),
              skill_book_module,
            ),
            drop_module,
          ),
          damage_number_set,
        ),
        _,
      ) = it
      let stage = Stage::new(
        @map.get_portals_animations(map_module),
        monster_module.get_map_mobs(),
        drop_module.get_map_drops(),
        inventory_module.get_inventory(),
        npc_module.get_npcs(),
        char_look_module,
        skill_book_module,
        char_stats_mod,
        damage_number_set,
        add_io_task,
        network,
      )
      stage_ref.val = Some(stage)
    })
  char_stats_mod_f
  .combine(shop_mod_f)
  .combine(stage_f)
  .combine(login_mod_f)
  .combine(inventory_module_fut)
  .combine(skill_book_mod_f)
  .map(fn(it) {
    let (
      (
        (((char_stats_module, shop_module), _stage), login_module),
        inventory_module,
      ),
      skill_book_module,
    ) = it
    network.reset_handlers(net_handler_map.iter() |> @immut/hashmap.from_iter)
    timer.reset()
    ui.change_state(UIStateLogin::new())
    {
      login_module,
      inventory_module,
      skill_book_module,
      char_stats_module,
      shop_module,
    }
  })
}

///|
pub fn Game::update(self : Game, current_time : @utils.TimePoint) -> Unit {
  let elapsed = self.timer.stop(current_time)
  guard self.loaded_state.poll() is Some(loaded_state) else { return }
  self.processor.process_in()
  // TODO: reconnect
  // match self.processor.get_status() {
  //   @net.CLOSED => loaded_state.login_module.reconnect_if_needed()
  //   _ => ()
  // }
  loaded_state.login_module.update()
  let timestep = @config.step_time_ms * 1000
  // Update game with constant timestep as many times as possible.
  let acc = self.accumulator + elapsed.to_micro_seconds()
  let times = acc / timestep
  let remaining = acc - timestep * times
  self.accumulator = remaining
  let update_times = @math.minimum(times, 10) // avoid halt
  for _ in 0..<update_times {
    self.update_status()
  }
  self.io_service.run() // run once per frame, after update network
  self.scheduls.update(timestep * times) // low priority, low resolution

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(alpha)
}

///|
pub fn update_status(self : Game) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  let stage = self.stage.val.unwrap() // TODO: handle error
  match stage.update?() {
    Ok(_) => ()
    Err(e) => @log.error({ "err": e }, "failed to update stage")
  }
  self.ui.update()
  // Music::update_context();
}

///|
pub fn Game::draw(self : Game, alpha : Double) -> Unit {
  @graphics.GraphicsGL::get().clear_scene()
  let stage = self.stage.val.unwrap() // TODO: handle error
  stage.draw(alpha)
  self.ui.draw(alpha)
  @graphics.GraphicsGL::get().flush(1.0)
}

///|
fn setup_game_ui(
  ui : UI,
  stage : Stage,
  player : @player.Player,
  registry : @action.Registry,
  timer : @utils.Timer,
  map_module : @map.Module
) -> Unit {
  ui.change_state(UIStateGame::new(ui, stage, registry, timer))
  let stats = player.get_stats()
  ui.set_element(
    false,
    @ui.Element::new(
      fn(hooks) { @char_stats.StatusBarUI::new(stats, hooks) },
      @ui.UIElementType::STATUS_BAR,
    ),
  )
  ui.set_element(
    false,
    @ui.Element::new(
      fn(hooks) {
        let mini_map_ui = map_module.new_mini_map_ui(hooks.on_state_changed)
        stage.listen_map_change(fn(map_struct) {
          guard mini_map_ui.get_ui_model().active else { return false }
          mini_map_ui.set_map(
            map_struct.id,
            map_struct.map_info,
            map_struct.mini_map_resources,
          )
          true
        })
        mini_map_ui
      },
      @ui.UIElementType::MINI_MAP,
    ),
  )
}

///|
pub fn get_window(self : Game) -> Window {
  self.window
}

///|
pub fn Game::get_inventory_mod(self : Game) -> @inventory.Module? {
  self.loaded_state.poll().map(fn(it) { it.inventory_module })
}

///|
pub fn Game::get_skill_book_mod(self : Game) -> @skill_book.Module? {
  self.loaded_state.poll().map(fn(it) { it.skill_book_module })
}

///|
pub fn Game::get_char_stats_mod(self : Game) -> @char_stats.Module? {
  self.loaded_state.poll().map(fn(it) { it.char_stats_module })
}

///|
pub fn Game::get_keyboard_mod(self : Game) -> @keyboard.Module {
  self.keyboard_module
}

///|
pub fn Game::get_login_mod(self : Game) -> @login.Module? {
  self.loaded_state.poll().map(fn(it) { it.login_module })
}

///|
pub fn Game::get_stage(self : Game) -> Stage? {
  self.stage.val
}

///|
pub fn Game::get_shop_mod(self : Game) -> @shop.Module? {
  self.loaded_state.poll().map(fn(it) { it.shop_module })
}

///|
fn default_keymap() -> Map[String, @keyboard.Mapping] {
  let keymap = Map::new()
  keymap.set(
    @keyboard.arrowLeft,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::LEFT),
  )
  keymap.set(
    @keyboard.arrowRight,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::RIGHT),
  )
  keymap.set(
    @keyboard.arrowUp,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::UP),
  )
  keymap.set(
    @keyboard.arrowDown,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::DOWN),
  )
  keymap.set(
    @keyboard.enter,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::RETURN),
  )
  keymap.set(
    @keyboard.numpadEnter,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::RETURN),
  )
  keymap.set(
    @keyboard.tab,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::TAB),
  )
  keymap.set(
    @keyboard.space,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::JUMP),
  )
  keymap.set(
    @keyboard.keyX,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::ATTACK),
  )
  keymap.set(
    @keyboard.keyC,
    @keyboard.Mapping::ACTION(@keyboard.BasicActionId::PICKUP),
  )
  keymap
}
