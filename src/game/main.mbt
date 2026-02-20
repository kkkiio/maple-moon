///|
fn game_start(_delta : Double) -> Unit {
  @game_server.init_server()
  @login.setup_game_server_handlers()
  @game_scene.setup_game_server_handlers()
  @monster.setup_game_server_handlers()
  @drop.setup_game_server_handlers()
}

///|
fn main {
  @system.App::new()
  .with_image_smooth(false)
  .with_canvas_width(@graphics.view_size.0 |> Double::from_int)
  .with_canvas_height(@graphics.view_size.1 |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(@logic_fps.logic_fps_system, system_name="logic_fps_system")
  .add_system(game_start, schedule=Startup)
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(@ui.ui_system, system_name="ui_system")
  .add_system(@ui.number_system, system_name="number_system")
  .add_system(
    @inventory_ui.inventory_ui_system,
    system_name="inventory_ui_system",
  )
  .add_system(@char_look.char_look_system, system_name="char_look_system")
  .add_system(
    @char_look.update_after_image_system,
    system_name="after_image_system",
  )
  .add_system(@graphics.effect_layer_system, system_name="effect_layer_system")
  .add_system(@login.select_char_system, system_name="select_char_system")
  .add_system(
    @game_scene.scene_transition_system,
    system_name="scene_transition_system",
  )
  .add_system(@player.player_state_system, system_name="player_state_system")
  .add_system(@map.background_system, system_name="background_system")
  .add_system(@map.tile_objects_system, system_name="tile_objects_system")
  .add_system(@map.portal_system, system_name="portal_system")
  .add_system(@monster.map_monsters_system, system_name="map_monsters_system")
  .add_system(@monster.mob_hpbars_system, system_name="mob_hpbars_system")
  .add_system(@drop.map_drops_system, system_name="map_drops_system")
  .add_system(@combat_impl.combat_system, system_name="combat_system")
  .add_system(@game_server.server_system, system_name="server_system")
  .add_system(@io_service.io_system, system_name="io_system")
  .run()
}
