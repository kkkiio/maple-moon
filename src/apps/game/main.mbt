///|
extern "js" fn new_seed_from_time() -> Bytes =
  #| () => {
  #|   const seed = new Uint8Array(32);
  #|   const now = BigInt(Date.now());
  #|   for (let i = 0; i < 8; i += 1) {
  #|     seed[i] = Number((now >> BigInt(i * 8)) & 0xffn);
  #|   }
  #|   const perf = Math.floor(
  #|     (typeof performance !== "undefined" ? performance.now() : 0) * 1000
  #|   );
  #|   for (let i = 0; i < 8; i += 1) {
  #|     seed[8 + i] = (perf >> ((i % 4) * 8)) & 0xff;
  #|   }
  #|   const rnd = Math.floor(Math.random() * 0xffffffff);
  #|   for (let i = 0; i < 8; i += 1) {
  #|     seed[16 + i] = (rnd >> ((i % 4) * 8)) & 0xff;
  #|   }
  #|   for (let i = 24; i < 32; i += 1) {
  #|     seed[i] = seed[i - 24] ^ seed[i - 8] ^ ((i * 37) & 0xff);
  #|   }
  #|   return Array.from(seed);
  #| }

///|
fn game_start() -> Unit {
  @local_server.default_rand_seed.val = new_seed_from_time()
  @passive.set_passive_randomizer(@random.Rand::new())
  @game_server.init_server()
  @select_char_ui.setup_game_server_handlers()
  @explorer_creation_ui.setup_game_server_handlers()
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
fn main {
  install_builtin_resource_loaders()
  @item.set_item_data_system(
    @item.ItemDataSystem::new(@resource.get_item_loader()),
  )
  let mut app = @app.App::new()
    .with_image_smooth(false)
    .with_viewport_width(@graphics.view_size.0 |> Double::from_int)
    .with_viewport_height(@graphics.view_size.1 |> Double::from_int)
    .with_fps(@graphics.fps)
    .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  app = app.add_system(
    Update,
    fn(_world) { @logic_fps.logic_fps_system(@time.delta()) },
    system_name="logic_fps_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { app_resource_setup_system(@time.delta()) },
    system_name="app_resource_setup_system",
  )
  app = app.add_system(Startup, fn(_world) { game_start() })
  app = app.add_system(
    Update,
    fn(_world) { @audio.audio_event_playback_system(@time.delta()) },
    system_name="audio_event_playback_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @audio.audio_playback_system(@time.delta()) },
    system_name="audio_playback_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @ui.ui_system(@time.delta()) },
    system_name="ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @ui.number_system(@time.delta()) },
    system_name="number_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @inventory_ui.inventory_ui_system(@time.delta()) },
    system_name="inventory_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @shop_ui.shop_ui_system(@time.delta()) },
    system_name="shop_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @equip_system.equip_system(@time.delta()) },
    system_name="equip_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @item.get_item_data_system().run(@time.delta()) },
    system_name="item_data_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @char_look.char_look_system(@time.delta()) },
    system_name="char_look_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @char_look.update_after_image_system(@time.delta()) },
    system_name="after_image_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @graphics.effect_layer_system(@time.delta()) },
    system_name="effect_layer_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @select_char_ui.select_char_ui_system(@time.delta()) },
    system_name="select_char_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) {
      @explorer_creation_ui.explorer_creation_ui_system(@time.delta())
    },
    system_name="explorer_creation_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @npc_talk_ui.npc_talk_ui_system(@time.delta()) },
    system_name="npc_talk_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @status_bar_ui.status_bar_ui_system(@time.delta()) },
    system_name="status_bar_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @game_scene.scene_transition_system(@time.delta()) },
    system_name="scene_transition_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @game_scene.look_sync_system(@time.delta()) },
    system_name="look_sync_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @controller.player_controller_system(@time.delta()) },
    system_name="player_controller_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @map.background_system(@time.delta()) },
    system_name="background_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @map.tile_objects_system(@time.delta()) },
    system_name="tile_objects_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @map.portal_system(@time.delta()) },
    system_name="portal_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @mini_map_ui.mini_map_ui_system(@time.delta()) },
    system_name="mini_map_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @world_map_ui.world_map_ui_system(@time.delta()) },
    system_name="world_map_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @quest_icon.quest_icon_system(@time.delta()) },
    system_name="quest_icon_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @quest_log_ui.quest_log_ui_system(@time.delta()) },
    system_name="quest_log_ui_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @npc.map_npcs_system(@time.delta()) },
    system_name="map_npcs_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @cursor.cursor_system(@time.delta()) },
    system_name="cursor_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @monster.map_monsters_system(@time.delta()) },
    system_name="map_monsters_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @monster.mob_hpbars_system(@time.delta()) },
    system_name="mob_hpbars_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @drop.map_drops_system(@time.delta()) },
    system_name="map_drops_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @bullet.bullet_system(@time.delta()) },
    system_name="bullet_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @combat_system.combat_system(@time.delta()) },
    system_name="combat_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @passive.passive_system(@time.delta()) },
    system_name="passive_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @game_server.server_system(@time.delta()) },
    system_name="server_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @io_service.io_system(@time.delta()) },
    system_name="io_system",
  )
  app = app.add_system(
    Update,
    fn(_world) { @console.console_input_injection_system(@time.delta()) },
    system_name="console_input_injection_system",
  )
  app.run()
}
