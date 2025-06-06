///|
typealias UI = @ui.UI

///|
pub(all) struct Game {
  timer : @utils.Timer
  mut accumulator : Int
  processor : @net.Network
  loaded_state : @utils.Future[LoadedState]
  poll_service : @io_task.PollService
  io_service : @io_task.IOService
  scheduls : @schedule.Schedules
  stage : Ref[Stage?]
  keyboard_module : @keyboard.Module
}

///|
struct LoadedState {
  window : Window
  ui : UI
  login_module : @login.Module
  inventory_module : @inventory.Module
  skill_book_module : @skill_book.Module
  char_stats_module : @char_stats.Module
  shop_module : @shop.Module
  quest_module : @quest.Module
}

///|
pub fn Game::new() -> Game {
  @config.global().set_hardware_info()
  let timer = @utils.Timer::new(fn() {
    now_micro() |> @utils.TimePoint::from_micro
  })
  let processor = @net.Network::init()
  let keyboard_module = @keyboard.Module::new(default_keymap(), processor)
  let poll_service = @io_task.PollService::new()
  let io_service = @io_task.IOService::new()
  let scheduls = @schedule.Schedules::new()
  let stage = Ref::new(None)
  {
    timer,
    accumulator: 0,
    processor,
    loaded_state: load_modules(
      timer, processor, poll_service, io_service, scheduls, stage, keyboard_module,
    ),
    poll_service,
    io_service,
    scheduls,
    stage,
    keyboard_module,
  }
}

///|
fn load_modules(
  timer : @utils.Timer,
  network : @net.Network,
  poll_service : @io_task.PollService,
  io_service : @io_task.IOService,
  scheduls : @schedule.Schedules,
  stage_ref : Ref[Stage?],
  keyboard_module : @keyboard.Module
) -> @utils.Future[LoadedState] {
  let basic_loader_fut = io_service
    .submit(fn() {
      @resource.SyncLoader::load(
        "Basic",
        "https://maple-res.kkkiiox.work/UI/Basic.img.json",
        @resource.ImageLoader::get_path_image_loader(),
      )
    })
    .map(fn(rs) {
      rs.unwrap() // TODO: handle error
    })
  let ui_fut = basic_loader_fut.map(fn(basic_loader) {
    let keyboard = keyboard_module.get_keyboard()
    UI::new(basic_loader, fn(keycode) { keyboard.get_mapping(keycode) })
  })
  let window_fut = ui_fut.map(fn(ui) {
    Window::new(ui, fn() { now_micro() |> @utils.TimePoint::from_micro })
  })
  let local_storage = @config.LocalStorage::new()
  fn get_stage() -> Stage {
    stage_ref.val.unwrap() // TODO: handle error
  }

  let string_loader_fut = io_service
    .submit(fn() {
      @resource.SyncLoader::load(
        "String",
        "https://maple-res.kkkiiox.work/String/nx.json",
        @resource.ImageLoader::get_path_image_loader(),
      )
    })
    .map(fn(rs) {
      rs.unwrap() // TODO: handle error
    })
  let add_io_task = fn(task) { poll_service.add(task) }
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
  // character stat handlers
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
  // show status info handlers
  let show_status_info_handler_map = {}
  fn merge_show_status_info_handler_map(
    handlers : Map[Int, @game_mod.SubRouteHandler]
  ) {
    for sub_id, handler in handlers {
      show_status_info_handler_map.set(sub_id, handler)
    }
  }

  let char_look_module_f = string_loader_fut
    .bind(fn(string_loader) {
      @char_look.Module::load(
        fn(f) {
          guard get_stage().get_player() is Some(player) else { return }
          player.character.look = f(player.character.look)
        },
        io_service,
        string_loader,
      )
    })
    .tap(fn(mod) { merge_stat_handlers(mod.make_stat_handlers()) })
  let map_module = @map.Module::load()
  let inventory_module_fut = string_loader_fut
    .bind(fn(string_loader) {
      @inventory.Module::load(
        fn() { get_stage().get_player() },
        network,
        string_loader,
      )
    })
    .tap(fn(mod) {
      merge_handlers(mod.make_handlers())
      merge_actions(mod.make_actions())
      merge_stat_handlers(mod.make_stat_handlers())
      merge_show_status_info_handler_map(mod.make_show_status_info_handlers())
    })
  let ref_render_fut = string_loader_fut.map(fn(string_loader) {
    @markup_text.RefRender::new(string_loader, fn() {
      guard get_stage().get_player() is Some(player) else { return "" }
      player.character.get_name()
    })
  })
  let npc_module_fut = string_loader_fut
    .combine(ref_render_fut)
    .combine(ui_fut)
    .bind(fn(it) {
      let ((string_loader, ref_render), ui) = it
      @npc.Module::load(ui, network, ref_render, string_loader, io_service)
    })
    .tap(fn(mod) { merge_handlers(mod.make_handlers()) })
  let quest_module_fut = npc_module_fut
    .combine(inventory_module_fut)
    .combine(ref_render_fut)
    .bind(fn(it) {
      let ((mod, inventory_module), ref_render) = it
      @quest.Module::load(
        network,
        inventory_module.get_inventory(),
        ref_render,
        fn(args) { mod.open_npc_talk_ui(args) },
      )
    })
    .map(fn(it) {
      match it {
        Ok(quest_module) => quest_module
        Err(err) => {
          @log.error({ "err": err }, "failed to load quest module")
          panic()
        }
      }
    })
    .tap(fn(mod) {
      merge_handlers(mod.make_handlers())
      merge_show_status_info_handler_map(mod.make_show_status_info_handlers())
    })
  let status_bar_loader_fut = io_service
    .submit(fn() {
      @resource.SyncLoader::load(
        "StatusBar",
        "https://maple-res.kkkiiox.work/UI/StatusBar3.img.json",
        @resource.ImageLoader::get_path_image_loader(),
      )
    })
    .map(fn(rs) {
      rs.unwrap() // TODO: handle error
    })
  let login_mod_f = char_look_module_f
    .combine(ui_fut)
    .bind(fn(it) {
      let (mod, ui) = it
      @login.Module::load(network, ui, mod, io_service, local_storage).map(fn(
        login_module
      ) {
        (login_module, ui)
      })
    })
    .combine(status_bar_loader_fut)
    .combine(inventory_module_fut)
    .combine(map_module)
    .combine(quest_module_fut)
    .map(fn(it) {
      let (
        ((((login_module, ui), status_bar_loader), inventory_module), map_module
        ),
        quest_module,
      ) = it
      let handlers = login_module.make_handlers(
        fn(map_id, portal_id) { get_stage().transition(map_id, portal_id) },
        fn(char_entry, cooldowns, callback) {
          get_stage().set_player_stage(char_entry, cooldowns, callback)
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
            status_bar_loader,
          )
        },
        quest_module,
      )
      merge_handlers(handlers)
      login_module
    })
  let monster_module_fut = string_loader_fut
    .map(fn(string_loader) {
      @monster.Module::new(add_io_task, network, string_loader)
    })
    .tap(fn(mod) {
      merge_handlers(
        mod.make_handlers(fn() {
          get_stage().get_player().map(fn(p) { p.get_stats() })
        }),
      )
    })
  let drop_module = string_loader_fut
    .bind(fn(string_loader) { @drop.Module::load(string_loader) })
    .tap(fn(mod) {
      merge_handlers(
        mod.make_handlers(fn(id) {
          get_stage().get_character(id).map(fn(c) { c.get_phobj() })
        }),
      )
    })
  let char_stats_mod_f = @char_stats.Module::load(network).tap(fn(mod) {
    merge_stat_handlers(mod.make_stat_handlers())
  })
  let skill_book_mod_f = string_loader_fut
    .bind(fn(string_loader) {
      @skill_book.Module::load(
        fn() { get_stage().get_player() },
        network,
        string_loader,
      )
    })
    .tap(fn(mod) {
      merge_handlers(mod.make_handlers())
      merge_actions(mod.make_actions())
    })
  let shop_mod_f = string_loader_fut
    .bind(fn(string_loader) { @shop.Module::load(network, string_loader) })
    .map(fn(it) {
      let mod = it
      merge_handlers(mod.make_handlers())
      mod
    })
  let change_stat_handler = make_change_stats_handler(stat_handler_map, fn() {
    guard get_stage().get_player() is Some(player) else { return }
    player.recalc_stats(false)
  })
  net_handler_map.set(change_stat_handler.0, change_stat_handler.1)
  let show_status_info_handler = make_show_status_info_handler(
    show_status_info_handler_map,
  )
  net_handler_map.set(show_status_info_handler.0, show_status_info_handler.1)
  let job_module = @job.Module::new(fn(job_id) {
    guard get_stage().get_player() is Some(player) else { return }
    player.change_job(job_id)
  })
  merge_stat_handlers(job_module.make_stat_handlers())
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
  let damage_number_set = @ui.NumberSet::load()
  let stage_f = map_module
    .combine(string_loader_fut)
    .combine(monster_module_fut)
    .combine(inventory_module_fut)
    .combine(npc_module_fut)
    .combine(quest_module_fut)
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
                (
                  (
                    (
                      (
                        ((map_module, string_loader), monster_module),
                        inventory_module,
                      ),
                      npc_module,
                    ),
                    quest_module,
                  ),
                  char_look_module,
                ),
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
      let npcs = npc_module.get_npcs()
      let quests = quest_module.get_map_quests()
      npcs.listen_npc_changes(fn(event) {
        match event {
          @map_object.MapObjectEvent::Add(npc) =>
            quests.add_npc(npc.get_npc_id(), npc.get_npc_object())
          @map_object.MapObjectEvent::Remove(oid) => quests.remove_npc(oid)
          @map_object.MapObjectEvent::Clear => quests.clear()
        }
        true
      })
      let stage = Stage::new(
        map_module.get_portals_animations(),
        monster_module.get_map_mobs(),
        drop_module.get_map_drops(),
        inventory_module.get_inventory(),
        npcs,
        quests,
        char_look_module,
        skill_book_module,
        char_stats_mod,
        damage_number_set,
        add_io_task,
        network,
        string_loader,
        io_service,
      )
      stage_ref.val = Some(stage)
    })
  char_stats_mod_f
  .combine(ui_fut)
  .combine(window_fut)
  .combine(shop_mod_f)
  .combine(stage_f)
  .combine(login_mod_f)
  .combine(inventory_module_fut)
  .combine(skill_book_mod_f)
  .combine(quest_module_fut)
  .map(fn(it) {
    let (
      (
        (
          (
            ((((char_stats_module, ui), window), shop_module), _stage),
            login_module,
          ),
          inventory_module,
        ),
        skill_book_module,
      ),
      quest_module,
    ) = it
    network.reset_handlers(net_handler_map.iter() |> @immut/hashmap.from_iter)
    timer.reset()
    ui.change_state(UIStateLogin::new())
    {
      ui,
      window,
      login_module,
      inventory_module,
      skill_book_module,
      char_stats_module,
      shop_module,
      quest_module,
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
    self.update_status(loaded_state)
  }
  self.poll_service.run() // run once per frame, after update network
  self.scheduls.update(timestep * times) // low priority, low resolution

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(alpha, loaded_state)
}

///|
pub fn update_status(self : Game, loaded_state : LoadedState) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  let stage = self.stage.val.unwrap() // TODO: handle error
  match stage.update?() {
    Ok(_) => ()
    Err(e) => @log.error({ "err": e }, "failed to update stage")
  }
  loaded_state.ui.update()
  // Music::update_context();
}

///|
pub fn Game::draw(
  self : Game,
  alpha : Double,
  loaded_state : LoadedState
) -> Unit {
  @graphics.GraphicsGL::get().clear_scene()
  let stage = self.stage.val.unwrap() // TODO: handle error
  stage.draw(alpha)
  loaded_state.ui.draw(alpha)
  @graphics.GraphicsGL::get().flush(1.0)
}

///|
fn setup_game_ui(
  ui : UI,
  stage : Stage,
  player : @player.Player,
  registry : @action.Registry,
  timer : @utils.Timer,
  map_module : @map.Module,
  status_bar_loader : @resource.SyncLoader
) -> Unit {
  ui.change_state(UIStateGame::new(ui, stage, registry, timer))
  let stats = player.get_stats()
  ui.set_element(
    false,
    @ui.Element::new(
      fn(hooks) {
        @char_stats.StatusBarUI::new(stats, hooks, status_bar_loader)
      },
      @ui.UIElementType::STATUS_BAR,
    ),
  )
  ui.set_element(
    false,
    @ui.Element::new(
      fn(hooks) {
        let ui_model = hooks.ui_model
        let mini_map_ui = map_module.new_mini_map_ui(
          ui_model,
          hooks.on_state_changed,
        )
        stage.listen_map_change(fn(map_struct) {
          guard ui_model.active else { return false }
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
pub fn Game::get_window(self : Game) -> Window? {
  self.loaded_state.poll().map(fn(it) { it.window })
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
pub fn Game::get_quest_mod(self : Game) -> @quest.Module? {
  self.loaded_state.poll().map(fn(it) { it.quest_module })
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

///|
// fn get_countset(basic_loader : @resource.SyncLoader) -> @graphics.Charset {
//   @graphics.Charset::from_resource(
//     basic_loader.load_res(["ItemNo"]),
//     @graphics.CharsetAlignment::LEFT,
//   )
// }
