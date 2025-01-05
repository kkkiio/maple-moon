///|
typealias UI = @ui.UI

///|
pub(all) struct Game {
  window : Window
  timer : @utils.Timer
  mut accumulator : Int
  ui : UI
  processor : @net.PacketProcessor
  loaded_state : @utils.Future[LoadedState]
  io_service : @io_task.Service
  scheduls : @schedule.Schedules
  stage : Ref[Stage?]
}

///|
struct LoadedState {
  login_module : @login.Module
}

///|
pub fn Game::new() -> Game {
  @config.global().set_hardware_info()
  let timer = @utils.Timer::new(fn() {
    now_micro() |> @utils.TimePoint::from_micro
  })
  let keyboard = Keyboard::default()
  let ui = UI::new(fn(keycode) { keyboard.get_mapping(keycode) })
  let window = Window::new(ui, fn() {
    now_micro() |> @utils.TimePoint::from_micro
  })
  let processor = @net.PacketProcessor::init()
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
      ui, timer, processor, io_service, scheduls, stage,
    ),
    io_service,
    scheduls,
    stage,
  }
}

///|
fn load_modules(
  ui : UI,
  timer : @utils.Timer,
  packet_processor : @net.PacketProcessor,
  io_service : @io_task.Service,
  scheduls : @schedule.Schedules,
  stage_ref : Ref[Stage?]
) -> @utils.Future[LoadedState] {
  fn get_stage() -> Stage {
    stage_ref.val.unwrap() // TODO: handle error
  }

  let add_io_task = fn(task) { io_service.add(task) }
  let action_registry = @action.Registry::new()
  let action_map = {}
  fn merge_actions(map : Map[@keyboard.ActionId, @action.Descriptor]) -> Unit {
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
      guard let Some(player) = get_stage().get_player() else { None => return }
      player.character.look = f(player.character.look)
    },
    io_service,
  ).tap(fn(mod) { merge_stat_handlers(mod.make_stat_handlers()) })
  let map_module = @map.Module::load()
  let inventory_module = @inventory.Module::load(fn() {
    get_stage().get_player()
  }).tap(fn(mod) {
    merge_handlers(mod.make_handlers())
    merge_actions(mod.make_actions())
    merge_stat_handlers(mod.make_stat_handlers())
  })
  let login_mod_f = char_look_module_f
    .bind(fn(mod) { @login.Module::load(packet_processor, ui, mod, io_service) })
    .combine(inventory_module)
    .map(fn(it) {
      let (login_module, inventory_module) = it
      merge_handlers(
        login_module.make_handlers(
          fn(map_id, portal_id) { get_stage().transition(map_id, portal_id) },
          fn(char_entry, callback) {
            get_stage().set_player_stage(char_entry, callback)
          },
          inventory_module.get_inventory(),
          fn(player) {
            setup_game_ui(ui, get_stage(), player, action_registry, timer)
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
    packet_processor,
  ).tap(fn(mod) { merge_handlers(mod.make_handlers()) })
  let char_stats_mod_f = @char_stats.Module::load(fn() {
    get_stage().get_player().map(fn(p) { p.get_stats() })
  }).tap(fn(mod) {
    merge_actions(mod.make_actions())
    merge_stat_handlers(mod.make_stat_handlers())
  })
  let skill_book_mod_f = @skill_book.Module::load(fn() {
    get_stage().get_player()
  }).tap(fn(mod) {
    merge_handlers(mod.make_handlers())
    merge_actions(mod.make_actions())
  })
  let shop_mod_f = @shop.Module::load(ui).map(fn(it) {
    let mod = it
    merge_handlers(
      mod.make_handlers(
        fn() { get_stage().get_player().map(fn(p) { p.character.look }) },
        fn() { Some(get_stage().get_inventory()) },
      ),
    )
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
    guard let Some(player) = get_stage().get_player() else { None => return }
    player.recalc_stats(false)
  })
  net_handler_map.set(change_stat_handler.0, change_stat_handler.1)
  let job_module = @job.Module::new(fn(job_id) {
    guard let Some(player) = get_stage().get_player() else { None => return }
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
    guard let Some(player) = get_stage().get_player() else { None => return }
    player.recalc_stats(false)
  })
  let loading_mods = [
    @utils.Future::from_value(
      @heal_over_time.new_module(scheduls, packet_processor, fn() {
        get_stage().get_player().map(fn(p) { p.get_stats() })
      }),
    ),
  ]
  // packet_switch.push((FAME_RESPONSE, FameResponseHandler::new()))
  // packet_switch.push((ADD_COOLDOWN, AddCooldownHandler::new()))
  // NPC Interaction Handlers
  let damage_number_set = @ui.NumberSet::load()
  let stage_f = map_module
    .combine(inventory_module)
    .combine(npc_module)
    .combine(char_look_module_f)
    .combine(drop_module)
    .combine(damage_number_set)
    .combine(@utils.Future::all_of(loading_mods))
    .map(fn(it) {
      let (
        (
          (
            (((map_module, inventory_module), npc_module), char_look_module),
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
        damage_number_set,
        add_io_task,
        packet_processor,
      )
      stage_ref.val = Some(stage)
    })
  char_stats_mod_f
  .combine(shop_mod_f)
  .combine(skill_book_mod_f)
  .combine(stage_f)
  |> to_wait
  |> @utils.Future::combine(login_mod_f)
  |> @utils.Future::map(fn(it) {
    let (_, login_module) = it
    action_registry.reset_actions(action_map.iter() |> @immut/hashmap.from_iter)
    packet_processor.reset_handlers(
      net_handler_map.iter() |> @immut/hashmap.from_iter,
    )
    timer.reset()
    ui.change_state(UIStateLogin::new(login_module))
    { login_module, }
  })
}

///|
pub fn update(self : Game, current_time : @utils.TimePoint) -> Unit {
  let elapsed = self.timer.stop(current_time)
  guard let Some(loaded_state) = self.loaded_state.poll() else {
    None => return
  }
  self.processor.process_in()
  match self.processor.get_status() {
    @net.CLOSED => loaded_state.login_module.reconnect_if_needed()
    _ => ()
  }
  loaded_state.login_module.update()
  let timestep = @constants.step_time_ms * 1000
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
pub fn draw(self : Game, alpha : Double) -> Unit {
  self.window.begin()
  let stage = self.stage.val.unwrap() // TODO: handle error
  stage.draw(alpha)
  self.ui.draw(alpha)
  self.window.end()
}

///|
fn setup_game_ui(
  ui : UI,
  stage : Stage,
  player : @player.Player,
  registry : @action.Registry,
  timer : @utils.Timer
) -> Unit {
  ui.change_state(UIStateGame::new(ui, stage, registry, timer))
  let stats = player.get_stats()
  ui.set_element(
    false,
    @ui.Element::new(
      fn(hooks) { @char_stats.UIStatusBar::new(stats, hooks) },
      @ui.UIElementType::STATUS_BAR,
    ),
  )
}

///|
fn now_micro() -> Double = "time" "now_micro"

///|
pub fn get_window(self : Game) -> Window {
  self.window
}

///|
fn to_wait[T](future : @utils.Future[T]) -> @utils.Future[Unit] {
  future.map(fn(_v : T) { () })
}
