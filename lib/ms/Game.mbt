pub struct Game {
  timer : @utils.Timer
  mut accumulator : Int
  stage : Stage
  ui : UI
  login_module : @login.Module
  net_module : @net.Module
}

pub fn Game::start() -> Game {
  @config.global().set_hardware_info()
  let login_module = @login.Module::new()
  let monster_module = @monster.Module::new()
  let drop_module = @drop.Module::new()
  let inventory_module = @inventory.Module::new(
    fn() { Stage::get().get_player() },
  )
  let timer = @utils.Timer::new(
    fn() { now_micro() |> @utils.TimePoint::from_micro },
  )
  let action_registry = @action.Registry::new()
  let ui = UI::new(timer, login_module, action_registry)
  g_ui.set(ui)
  let npc_module = @npc.Module::new(
    ui,
    fn() { Stage::get().get_player().unwrap().get_name() },
  )
  let stage = Stage::new(
    @map.MapPortalAnimations::load(),
    monster_module.get_map_mobs(),
    drop_module.get_map_drops(),
    inventory_module.get_inventory(),
    npc_module.get_npcs(),
  )
  g_stage.set(stage)
  let window = Window::new(fn() { now_micro() |> @utils.TimePoint::from_micro })
  g_window.set(window)
  let char_stats_module = @char_stats.Module::new(
    fn() { stage.get_player().map(fn(p) { p.get_stats() }) },
  )
  let sp_stat_id = @char_stats.StatId(1)
  let skill_book_module = @skill_book.Module::new(
    fn() { stage.get_player() },
    sp_stat_id,
  )
  let actions = char_stats_module.make_actions().iter()
    |> Iter::concat(inventory_module.make_actions().iter())
    |> Iter::concat(skill_book_module.make_actions().iter())
  for elem in actions {
    let (id, descriptor) = elem
    action_registry.register(id, descriptor)
  }
  let shop_module = @shop.Module::new(ui)
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

  let net_module = @net.Module::new(
    // Common handlers
    @immut/hashmap.from_array(
      login_module
      .make_handlers(
        fn(map_id, portal_id) { stage.transition(map_id, portal_id) },
        fn(char_entry) { stage.load_player(char_entry, sp_stat_id) },
        inventory_module.get_inventory(),
        fn(player) { setup_game_ui(player) },
      )
      .iter()
      // Player handlers
      // packet_switch.push((CHANGE_CHANNEL, ChangeChannelHandler::new()))
      // packet_switch.push((KEYMAP, KeymapHandler::new()))
      // packet_switch.push((SKILL_MACROS, SkillMacrosHandler::new()))
      |> Iter::append(
        (
          @net.CHANGE_STATS,
          @net.with_log(
            @net.CHANGE_STATS,
            fn(recv : @net.InPacket) {
              handle_change_stats!(
                stage.get_player().unwrap(),
                stage.get_inventory(),
                recv,
              )
            },
          ),
        ),
      )
      |> Iter::concat(npc_module.make_handlers().iter())

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
      |> Iter::concat(
        monster_module
        .make_handlers(fn() { stage.get_player().map(fn(p) { p.get_stats() }) })
        .iter(),
      )
      // // packet_switch.push((MOB_MOVED, MobMovedHandler::new()))
      // // packet_switch.push((MOB_MOVE_RESPONSE, MobMoveResponseHandler::new()))
      // // packet_switch.push((APPLY_MONSTER_STATUS, ApplyMobStatusHandler::new()))
      // // packet_switch.push((CANCEL_MONSTER_STATUS, CancelMobStatusHandler::new()))
      |> Iter::concat(
        drop_module
        .make_handlers(
          fn(id) { stage.get_character(id).map(fn(c) { c.get_phobj() }) },
        )
        .iter(),
      )
      |> Iter::concat(inventory_module.make_handlers().iter())
      // // packet_switch.push((HIT_REACTOR, HitReactorHandler::new()))
      // // packet_switch.push((SPAWN_REACTOR, SpawnReactorHandler::new()))
      // // packet_switch.push((REMOVE_REACTOR, RemoveReactorHandler::new()))
      // packet_switch.push((GIVE_BUFF, ApplyBuffHandler::new()))
      // packet_switch.push((CANCEL_BUFF, CancelBuffHandler::new()))
      |> Iter::append(
        (
          @net.RECALCULATE_STATS,
          fn(_recv : @net.InPacket) -> Unit {
            guard let Some(player) = stage.get_player() else { None => return  }
            player.recalc_stats(false)
          },
        ),
      )
      |> Iter::concat(skill_book_module.make_handlers().iter())
      // packet_switch.push((FAME_RESPONSE, FameResponseHandler::new()))
      // packet_switch.push((ADD_COOLDOWN, AddCooldownHandler::new()))
      // NPC Interaction Handlers
      |> Iter::concat(
        shop_module
        .make_handlers(
          fn() { stage.get_player().map(fn(p) { p.get_look() }) },
          fn() { Some(stage.get_inventory()) },
        )
        .iter(),
      )
      |> Iter::collect,
    ),
  )
  timer.start()
  { timer, accumulator: 0, stage, ui, login_module, net_module }
}

pub fn on_draw(self : Game, current_time : @utils.TimePoint) -> Unit {
  self.net_module.process_in()
  match @net.PacketProcessor::get().get_status() {
    @net.CLOSED => self.login_module.reconnect_if_needed()
    _ => ()
  }
  self.login_module.update()
  let timestep = @constants.step_time_ms * 1000
  let elapsed = self.timer.stop(current_time)
  if elapsed.to_seconds() >= 1 {
    @log.info(
      { "elapsed": elapsed.to_seconds() },
      "game idled, just wait for reconnect",
    )
    return
  }

  // Update game with constant timestep as many times as possible.
  let acc = self.accumulator + elapsed.to_micro_seconds()
  let times = acc / timestep
  let remaining = acc - timestep * times
  self.accumulator = remaining
  for _ in 0..<times {
    self.update()
  }

  // Draw the game. Interpolate to account for remaining time.
  let alpha = Double::from_int(self.accumulator) / Double::from_int(timestep)
  self.draw(alpha)
}

pub fn update(self : Game) -> Unit {
  // Window::get().check_events();
  // Window::get().update()
  match self.stage.update?() {
    Ok(_) => ()
    Err(e) => @log.error({ "err": e }, "failed to update stage")
  }
  self.ui.update()
  // Music::update_context();
}

pub fn draw(self : Game, alpha : Double) -> Unit {
  Window::get().begin()
  self.stage.draw(alpha)
  self.ui.draw(alpha)
  Window::get().end()
}

fn setup_game_ui(player : @player.Player) -> Unit {
  UI::get().change_state(UiState::GAME)
  let stats = player.get_stats()
  let stats_bar = @player.UIStatusBar::new(stats)
  UI::get().set_element(
    false,
    @ui.Element::new(stats_bar, @ui.UIElementType::STATUS_BAR),
  )
}

fn now_micro() -> Double = "time" "now_micro"
