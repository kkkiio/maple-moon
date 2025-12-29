///|
using @ui {type UI}

///|
pub(all) struct Game {
  timer : @utils.Timer
  mut accumulator : Int
  processor : @net.Network
  loaded_state : @utils.Future[LoadedState]
  // stage : Ref[Stage?]
  keyboard_module : @keyboard.Module
}

///|
struct LoadedState {
  window : Window
  ui : UI
  inventory_module : @inventory.Module
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
  {
    timer,
    accumulator: 0,
    processor,
    // loaded_state: io_service
    // .submit(fn() {
    //   load_modules(
    //     timer, processor, poll_service, io_service, scheduls, stage, keyboard_module,
    //   )
    // })
    // .map(fn(it) {
    //   it.unwrap() // TODO: handle error
    // }),
    loaded_state: @utils.Future::never(),
    // stage,
    keyboard_module,
  }
}

///|
async fn load_modules(
  timer : @utils.Timer,
  network : @net.Network,
  // stage_ref : Ref[Stage?],
  keyboard_module : @keyboard.Module,
) -> LoadedState {
  let net_handler_map = {}
  fn merge_handlers(
    handlers : Map[@net.Opcode, (@net.InPacket) -> Unit],
  ) -> Unit {
    for opcode, handler in handlers {
      net_handler_map.set(opcode, handler)
    }
  }

  merge_handlers(keyboard_module.make_handlers())
  // character stat handlers
  let stat_handler_map = {}
  fn merge_stat_handlers(
    handlers : Map[@maple_stat.Id, @game_mod.StatHandler],
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
    handlers : Map[Int, @game_mod.SubRouteHandler],
  ) {
    for sub_id, handler in handlers {
      show_status_info_handler_map.set(sub_id, handler)
    }
  }

  let keyboard = keyboard_module.get_keyboard()
  let ui = UI::new(fn(keycode) { keyboard.get_mapping(keycode) })
  let window = Window::new(ui)
  // let char_look_module = @char_look.Module::load()
  // merge_stat_handlers(char_look_module.make_stat_handlers())
  // let map_module = @map.Module::load()
  let inventory_module = @inventory.Module::load(fn() {
    ...
    // get_stage().get_player() 
  })
  merge_handlers(inventory_module.make_handlers())
  merge_stat_handlers(inventory_module.make_stat_handlers())
  merge_show_status_info_handler_map(
    inventory_module.make_show_status_info_handlers(),
  )
  let ref_render = @markup_text.RefRender::new(fn() {
    // guard get_stage().get_player() is Some(player) else { return "" }
    // player.character.get_name()
    ...
  })
  let npc_module = @npc.Module::load(ui, network, ref_render)
  merge_handlers(npc_module.make_handlers())
  let quest_module = @quest.Module::load(
    network,
    inventory_module.get_inventory(),
    ref_render,
    fn(args) { npc_module.open_npc_talk_ui(args) },
  )
  merge_handlers(quest_module.make_handlers())
  merge_show_status_info_handler_map(
    quest_module.make_show_status_info_handlers(),
  )
  let monster_module = @monster.Module::new()
  merge_handlers(
    monster_module.make_handlers(fn() {
      // get_stage().get_player().map(fn(p) { p.get_stats() })
      ...
    }),
  )
  let drop_module = @drop.Module::load()
  merge_handlers(
    drop_module.make_handlers(fn(id) {
      // get_stage().get_character(id).map(fn(c) { c.get_phobj() })
      ...
    }),
  )
  let char_stats_module = @char_stats.Module::load(network)
  merge_stat_handlers(char_stats_module.make_stat_handlers())
  // merge_actions(skill_book_module.make_actions())
  let shop_module = @shop.Module::load()
  merge_handlers(shop_module.make_handlers())
  let change_stat_handler = make_change_stats_handler(stat_handler_map, fn() {
    // guard get_stage().get_player() is Some(player) else { return }
    // player.recalc_stats(false)
    ...
  })
  net_handler_map.set(change_stat_handler.0, change_stat_handler.1)
  let show_status_info_handler = make_show_status_info_handler(
    show_status_info_handler_map,
  )
  net_handler_map.set(show_status_info_handler.0, show_status_info_handler.1)
  let job_module = @job.Module::new(fn(job_id) {
    // guard get_stage().get_player() is Some(player) else { return }
    // player.change_job(job_id, io_service)
    ...
  })
  merge_stat_handlers(job_module.make_stat_handlers())
  net_handler_map.set(@net.RECALCULATE_STATS, fn(
    _recv : @net.InPacket,
  ) -> Unit {
    // guard get_stage().get_player() is Some(player) else { return }
    // player.recalc_stats(false)
    ...
  })
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
  network.reset_handlers(net_handler_map.iter() |> @immut/hashmap.from_iter)
  timer.reset()
  ui.change_state(UIStateLogin::new())
  { ui, window, inventory_module, char_stats_module, shop_module, quest_module }
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
  let timestep = @logic_fps.STEP_TIME_MS * 1000
  // Update game with constant timestep as many times as possible.
  let acc = self.accumulator + elapsed.to_micro_seconds()
  let times = acc / timestep
  let remaining = acc - timestep * times
  self.accumulator = remaining
  let update_times = @cmp.minimum(times, 10) // avoid halt
  for _ in 0..<update_times {
    self.update_status(loaded_state)
  }

  // Draw the game. Interpolate to account for remaining time.
  let _alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  // self.draw(alpha)
}

///|
pub fn Game::update_status(self : Game, loaded_state : LoadedState) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  ...
  // let stage = self.stage.val.unwrap() // TODO: handle error
  // match (try? stage.update()) {
  //   Ok(_) => ()
  //   Err(e) => @log.error({ "err": e }, "failed to update stage")
  // }
  // loaded_state.ui.update()
  // Music::update_context();
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

///|
extern "js" fn now_micro() -> Double =
  #| () => performance.now() * 1000
