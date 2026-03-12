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
fn game_start(_delta : Double) -> Unit {
  @local_server.default_rand_seed.val = new_seed_from_time()
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
  @inventory_ui.init_inventory_ui()
  @shop_ui.init_shop_ui()
  @gm.install()
}

///|
fn main {
  install_builtin_resource_loaders()
  @item.set_item_data_system(
    @item.ItemDataSystem::new(@resource.get_item_loader()),
  )
  @system.App::new()
  .with_image_smooth(false)
  .with_viewport_width(@graphics.view_size.0 |> Double::from_int)
  .with_viewport_height(@graphics.view_size.1 |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(@logic_fps.logic_fps_system, system_name="logic_fps_system")
  .add_system(game_start, schedule=Startup)
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(
    @audio.audio_event_playback_system,
    system_name="audio_event_playback_system",
  )
  .add_system(@audio.audio_playback_system, system_name="audio_playback_system")
  .add_system(@ui.ui_system, system_name="ui_system")
  .add_system(@ui.number_system, system_name="number_system")
  .add_system(
    @inventory_ui.inventory_ui_system,
    system_name="inventory_ui_system",
  )
  .add_system(@shop_ui.shop_ui_system, system_name="shop_ui_system")
  .add_system(@equip_system.equip_system, system_name="equip_system")
  .add_system(
    delta => @item.get_item_data_system().run(delta),
    system_name="item_data_system",
  )
  .add_system(@char_look.char_look_system, system_name="char_look_system")
  .add_system(
    @char_look.update_after_image_system,
    system_name="after_image_system",
  )
  .add_system(@graphics.effect_layer_system, system_name="effect_layer_system")
  .add_system(
    @select_char_ui.select_char_ui_system,
    system_name="select_char_ui_system",
  )
  .add_system(
    @game_scene.scene_transition_system,
    system_name="scene_transition_system",
  )
  .add_system(@game_scene.look_sync_system, system_name="look_sync_system")
  .add_system(
    @controller.player_controller_system,
    system_name="player_controller_system",
  )
  .add_system(@map.background_system, system_name="background_system")
  .add_system(@map.tile_objects_system, system_name="tile_objects_system")
  .add_system(@map.portal_system, system_name="portal_system")
  .add_system(@mini_map_ui.mini_map_ui_system, system_name="mini_map_ui_system")
  .add_system(
    @world_map_ui.world_map_ui_system,
    system_name="world_map_ui_system",
  )
  .add_system(@npc.map_npcs_system, system_name="map_npcs_system")
  .add_system(@monster.map_monsters_system, system_name="map_monsters_system")
  .add_system(@monster.mob_hpbars_system, system_name="mob_hpbars_system")
  .add_system(@drop.map_drops_system, system_name="map_drops_system")
  .add_system(@bullet.bullet_system, system_name="bullet_system")
  .add_system(@combat_system.combat_system, system_name="combat_system")
  .add_system(@passive.passive_system, system_name="passive_system")
  .add_system(@game_server.server_system, system_name="server_system")
  .add_system(@io_service.io_system, system_name="io_system")
  .run()
}
