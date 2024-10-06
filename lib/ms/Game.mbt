pub struct Game {
  task_scheduler : TaskScheduler
  mut accumulator : Int
}

pub fn Game::start() -> Game {
  @config.global().set_hardware_info()
  let task_scheduler = { tasks: [] }
  let login_module = @login.Module::new(
    fn(x) { task_scheduler.add_new_task(x) },
  )
  let monster_module = @monster.Module::new()
  let mob_combat = @monster_combat.MobCombat::new(monster_module.get_map_mobs())
  let drop_module = @drop.Module::new()
  let inventory_module = @inventory.Module::new()
  let stage = Stage::new(
    monster_module.get_map_mobs(),
    drop_module.get_map_drops(),
    inventory_module.get_inventory(),
  )
  g_stage.set(stage)
  let skill_book_module = @skill_book.Module::new()
  // ( 

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

  @net.PacketProcessor::initialize(
    // Common handlers
    @immut/hashmap.from_array(
      (@net.PING, @net.PingHandler::default())
      |> Iter::singleton
      |> Iter::concat(login_module.make_handlers().iter())
      |> Iter::append((SET_FIELD, SetFieldHandler::new(login_module)))
      // Player handlers
      // packet_switch.push((CHANGE_CHANNEL, ChangeChannelHandler::new()))
      // packet_switch.push((KEYMAP, KeymapHandler::new()))
      // packet_switch.push((SKILL_MACROS, SkillMacrosHandler::new()))
      |> Iter::append((@net.CHANGE_STATS, ChangeStatsHandler::new(stage)))

      // MapObject handlers
      // // packet_switch.push((SPAWN_CHAR, SpawnCharHandler::new()))
      // // packet_switch.push((CHAR_MOVED, CharMovedHandler::new()))
      // // packet_switch.push((UPDATE_CHARLOOK, UpdateCharLookHandler::new()))
      // // packet_switch.push((SHOW_FOREIGN_EFFECT, ShowForeignEffectHandler::new()))
      // // packet_switch.push((GIVE_FOREIGN_BUFF, GiveForeignBuffHandler::new()))
      // // packet_switch.push((CANCEL_FOREIGN_BUFF, CancelForeignBuffHandler::new()))
      // // packet_switch.push((REMOVE_CHAR, RemoveCharHandler::new()))
      // // packet_switch.push((SPAWN_PET, SpawnPetHandler::new()))
      |> Iter::append((SPAWN_NPC, SpawnNpcHandler::new()))
      |> Iter::append((SPAWN_NPC_C, SpawnNpcControllerHandler::new()))
      // |> Iter::append((SET_NPC_SCRIPTABLE, SetNpcScriptableHandler::new()))
      |> Iter::concat(monster_module.make_handlers().iter())
      |> Iter::append(
        (
          MOB_MOVED,
          MobMovedHandler::new(monster_module.get_map_mobs(), mob_combat),
        ),
      )
      |> Iter::append(
        (@net.MOB_MOVE_RESPONSE, MobMoveResponseHandler::new(mob_combat)),
      )
      // // packet_switch.push((MOB_MOVED, MobMovedHandler::new()))
      // // packet_switch.push((MOB_MOVE_RESPONSE, MobMoveResponseHandler::new()))
      // // packet_switch.push((APPLY_MONSTER_STATUS, ApplyMobStatusHandler::new()))
      // // packet_switch.push((CANCEL_MONSTER_STATUS, CancelMobStatusHandler::new()))
      |> Iter::append(
        (SHOW_MOB_HP, ShowMobHpHandler::new(monster_module.get_map_mobs())),
      )
      |> Iter::append(
        (KILL_MOB, KillMobHandler::new(monster_module.get_map_mobs())),
      )
      |> Iter::concat(
        drop_module.make_handlers(fn(id) { stage.get_character(id) }).iter(),
      )
      |> Iter::concat(
        inventory_module.make_handlers(fn() { stage.get_player() }).iter(),
      )
      // // packet_switch.push((HIT_REACTOR, HitReactorHandler::new()))
      // // packet_switch.push((SPAWN_REACTOR, SpawnReactorHandler::new()))
      // // packet_switch.push((REMOVE_REACTOR, RemoveReactorHandler::new()))
      // packet_switch.push((GIVE_BUFF, ApplyBuffHandler::new()))
      // packet_switch.push((CANCEL_BUFF, CancelBuffHandler::new()))
      |> Iter::append((RECALCULATE_STATS, RecalculateStatsHandler::new(stage)))
      |> Iter::concat(
        skill_book_module.make_handlers(fn() { stage.get_player() }).iter(),
      )
      // packet_switch.push((FAME_RESPONSE, FameResponseHandler::new()))
      // packet_switch.push((ADD_COOLDOWN, AddCooldownHandler::new()))
      // NPC Interaction Handlers
      |> Iter::append((NPC_DIALOGUE, NpcDialogueHandler::new(UI::get())))
      // |> Iter::append((OPEN_NPC_SHOP, OpenNpcShopHandler::new()))
      |> Iter::collect,
    ),
  )
  timer.start()
  @map.map_portals_animations.load()
  { accumulator: 0, task_scheduler }
}

pub fn stop(self : Game) -> Unit {
  // Sound::close();
}

pub fn on_draw(self : Game, time : TimePoint) -> Unit {
  let timestep = @constants.timestep * 1000
  let elapsed = Timer::get().stop(time)

  // Update game with constant timestep as many times as possible.
  self.accumulator += elapsed.to_micro_seconds()
  let times = self.accumulator / timestep
  self.accumulator -= timestep * times
  (0).until(times).each(fn(_i) { self.update() })

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(alpha)
}

pub fn update(self : Game) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  match Stage::get().update?() {
    Ok(_) => ()
    Err(e) => @log.error({ "err": e }, "failed to update stage")
  }
  UI::get().update()
  @net.PacketProcessor::get().process_in()
  // Music::update_context();
  self.task_scheduler.update_tasks()
}

pub fn draw(self : Game, alpha : Double) -> Unit {
  Window::get().begin()
  Stage::get().draw(alpha)
  UI::get().draw(alpha)
  Window::get().end()
}

// fn reset(self : Game, g : Gl_g) -> Result[Unit, String] {
// if (Error error = PacketProcessor::get().init(pApp)) {
//     return error;
// }
// std::cout << "Session init success." << std::endl;

// if (Error error = Window::get().init(pApp)) {
//     return error;
// }
// std::cout << "Window init success." << std::endl;
// if (Error error = Music::init()) {
//     return error;
// }
// std::cout << "Music init success." << std::endl;
// if (Error error = Sound::init()) {
//     return error;
// }
// std::cout << "Sound init success." << std::endl;

// return Error::NONE;
// Ok(())
// }

struct TaskScheduler {
  tasks : Array[@login.BgTask]
}

fn add_new_task(self : TaskScheduler, task : @login.BgTask) -> Unit {
  self.tasks.push(task)
}

fn update_tasks(self : TaskScheduler) -> Unit {
  self.tasks.retain(fn(task) { task.update().not() })
}
