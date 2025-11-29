///|
fn game_start(_delta : Double) -> Unit {
  @login.add_select_char_ui() catch {
    e => {
      @log.error({ "e": e.to_string() }, "add select char ui failed")
      panic()
    }
  }
}

///|
fn main {
  // @canvas.CanvasBackend::new().with_cross_origin(Some("anonymous")),
  @system.App::new()
  .with_image_smooth(false)
  .with_canvas_width(@graphics.view_size.0 |> Double::from_int)
  .with_canvas_height(@graphics.view_size.1 |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(@config.logic_fps_system, system_name="logic_fps_system")
  .add_system(game_start, schedule=Startup)
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(@login.select_char_system, system_name="select_char_system")
  .add_system(
    @game_scene.scene_transition_system,
    system_name="scene_transition_system",
  )
  .add_system(
    @game_scene.player_state_system,
    system_name="player_state_system",
  )
  .add_system(@map.background_system, system_name="background_system")
  .add_system(@combat_impl2.combat_system, system_name="combat_system")
  .run()
}
