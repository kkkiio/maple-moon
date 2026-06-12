///|
fn game_start() -> Unit {
  @passive.set_passive_randomizer(@random.Rand::new())
  @game_server.init_server()
  @select_char_ui.setup_game_server_handlers()
  @game_scene.setup_game_server_handlers()
  @npc.setup_game_server_handlers()
  @monster.setup_game_server_handlers()
  @drop.setup_game_server_handlers()
  @inventory_ui.setup_game_server_handlers()
  @inventory.setup_game_server_handlers()
  @shop_ui.setup_game_server_handlers()
  @quest_log.setup_game_server_handlers()
  @inventory_ui.init_inventory_ui()
  @shop_ui.init_shop_ui()
  @console.install()
}

///|
fn cleanup_for_change_map(_world : @ecs.World) -> Unit {
  @drop.clear_for_change_map()
  @bullet.clear_for_change_map()
  @monster.clear_for_change_map()
  @inventory_ui.clear_for_change_map()
  @shop_ui.clear_for_change_map()
  @world_map_ui.clear_for_change_map()
}

///|
fn cleanup_for_leave_world(_world : @ecs.World) -> Unit {
  @drop.clear_for_leave_world()
  @bullet.clear_for_leave_world()
  @monster.clear_for_leave_world()
  @inventory_ui.clear_for_leave_world()
  @shop_ui.clear_for_leave_world()
  @world_map_ui.clear_for_leave_world()
}

///|
/// Run the Maple Moon game with the platform backend selected by the entry
/// package.
///
/// The shared app installs game resources, local-server handlers, runtime
/// systems, and starts from `GameSetup`. Platform packages decide whether the
/// run uses WebGPU/JS or raylib/native.
///
/// # Example
/// ```moonbit nocheck
/// @game_app.run()
/// ```
pub fn run() -> Unit {
  @item.set_item_data_system(@item.ItemDataSystem::new())
  let app = @app.App()
    .with_image_smooth(false)
    .with_viewport_width(@graphics.view_size.0 |> Double::from_int)
    .with_viewport_height(@graphics.view_size.1 |> Double::from_int)
    .with_fps(@graphics.fps)
    .with_fixed_hz(@logic_fps.LOGIC_FPS.reinterpret_as_uint())
    // .add_plugin(@plugins.debug_plugin)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      @system.OnEnter(
        @game_state.transition(
          from=fn(phase) { phase is @game_state.GamePhase::GameActive(..) },
          to=fn(phase) { phase is @game_state.GamePhase::GameTransiting(..) },
        ),
      ),
      cleanup_for_change_map,
      system_name="cleanup_for_change_map",
    )
    .add_system(
      @system.OnEnter(
        @game_state.transition(
          from=fn(phase) {
            phase is @game_state.GamePhase::GameActive(..) ||
            phase is @game_state.GamePhase::GameTransiting(..) ||
            phase is @game_state.GamePhase::GameStart(..)
          },
          to=fn(phase) { phase is @game_state.GamePhase::SelectCharacter },
        ),
      ),
      cleanup_for_leave_world,
      system_name="cleanup_for_leave_world",
    )
    .add_system(
      Update,
      fn(world) { app_resource_setup_system(world) },
      system_name="app_resource_setup_system",
    )
    .add_system(Startup, fn(_world) { game_start() })
    .add_system(
      Update,
      fn(_world) { @audio.audio_event_playback_system(@time.delta()) },
      system_name="audio_event_playback_system",
    )
    .add_system(
      Update,
      fn(_world) { @audio.audio_playback_system(@time.delta()) },
      system_name="audio_playback_system",
    )
    .add_system(
      Update,
      fn(world) { @ui.ui_system(world) },
      system_name="ui_system",
    )
    .add_system(
      Update,
      fn(world) { @ui.number_system(world) },
      system_name="number_system",
    )
    .add_system(
      Update,
      fn(world) { @inventory_ui.inventory_ui_system(world) },
      system_name="inventory_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @shop_ui.shop_ui_system(world) },
      system_name="shop_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @equip_inventory.equip_inventory_system(world) },
      system_name="equip_inventory_system",
    )
    .add_system(
      Update,
      fn(_world) { @item.get_item_data_system().run(@time.delta()) },
      system_name="item_data_system",
    )
    .add_system(
      Update,
      fn(world) { @char_look.char_look_system(world) },
      system_name="char_look_system",
    )
    .add_system(
      Update,
      fn(world) { @char_look.update_after_image_system(world) },
      system_name="after_image_system",
    )
    .add_system(
      Update,
      fn(world) { @graphics.effect_layer_system(world) },
      system_name="effect_layer_system",
    )
    .add_system(
      Update,
      fn(world) { @select_char_ui.select_char_ui_system(world) },
      system_name="select_char_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @npc_talk_ui.npc_talk_ui_system(world) },
      system_name="npc_talk_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @status_bar_ui.status_bar_ui_system(world) },
      system_name="status_bar_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @game_scene.scene_transition_system(world) },
      system_name="scene_transition_system",
    )
    .add_system(
      Update,
      fn(world) { @game_scene.look_sync_system(world) },
      system_name="look_sync_system",
    )
    .add_system(
      Update,
      fn(world) { @controller.player_controller_input_system(world) },
      system_name="player_controller_input_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @controller.player_controller_fixed_system(world) },
      system_name="player_controller_fixed_system",
    )
    .add_system(
      Update,
      fn(world) { @ms_camera.camera_follow_system(world) },
      system_name="camera_follow_system",
    )
    .add_system(
      Update,
      fn(world) { @map.portal_system(world) },
      system_name="portal_system",
    )
    .add_system(
      Update,
      fn(world) { @map.tiled_background_motion_system(world) },
      system_name="tiled_background_motion_system",
    )
    .add_system(
      Update,
      fn(world) { @mini_map_ui.mini_map_ui_system(world) },
      system_name="mini_map_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @world_map_ui.world_map_ui_system(world) },
      system_name="world_map_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @quest_icon.quest_icon_system(world) },
      system_name="quest_icon_system",
    )
    .add_system(
      Update,
      fn(world) { @quest_log_ui.quest_log_ui_system(world) },
      system_name="quest_log_ui_system",
    )
    .add_system(
      Update,
      fn(world) { @npc.map_npcs_pointer_system(world) },
      system_name="map_npcs_pointer_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @npc.map_npcs_fixed_system(world) },
      system_name="map_npcs_fixed_system",
    )
    .add_system(
      Update,
      fn(world) { @cursor.cursor_system(world) },
      system_name="cursor_system",
    )
    .add_system(
      Update,
      fn(world) { @monster.map_monsters_render_system(world) },
      system_name="map_monsters_render_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @monster.map_monsters_fixed_system(world) },
      system_name="map_monsters_fixed_system",
    )
    .add_system(
      Update,
      fn(world) { @monster.mob_hpbars_system(world) },
      system_name="mob_hpbars_system",
    )
    .add_system(
      Update,
      fn(world) { @drop.map_drops_loading_system(world) },
      system_name="map_drops_loading_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @drop.map_drops_fixed_system(world) },
      system_name="map_drops_fixed_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @bullet.bullet_system(world) },
      system_name="bullet_system",
    )
    .add_system(
      FixedUpdate,
      fn(world) { @combat_system.combat_system(world) },
      system_name="combat_system",
    )
    .add_system(
      Update,
      fn(world) { @passive.passive_system(world) },
      system_name="passive_system",
    )
    .add_system(
      Update,
      fn(_world) { @game_server.server_system(@time.delta()) },
      system_name="server_system",
    )
    .add_system(
      Update,
      fn(world) { @io_service.io_system(world) },
      system_name="io_system",
    )
    .add_system(
      First,
      fn(world) { @console.console_input_injection_system(world) },
      system_name="console_input_injection_system",
    )
  @ecs.set_current_world(app.world())
  @game_state.init_state(@game_state.GamePhase::GameSetup)
  app.run()
}
