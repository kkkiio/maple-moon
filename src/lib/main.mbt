///|
priv struct EntryPoint {
  mut game : @ms.Game?
}

///|
let entrypoint : EntryPoint = { game: None }

///|
fn game_start(_delta : Double) -> Unit {
  let game = @ms.Game::new()
  @login.add_select_char_ui() catch {
    e => {
      @log.error({ "e": e.to_string() }, "add select char ui failed")
      panic()
    }
  }
  entrypoint.game = game |> Some
}

///|
fn main {
  // @canvas.CanvasBackend::new().with_cross_origin(Some("anonymous")),
  @system.App::new()
  .with_image_smooth(false)
  .with_canvas_width(@config.constants.get_viewwidth() |> Double::from_int)
  .with_canvas_height(@config.constants.get_viewheight() |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(@login.select_char_system, system_name="select_char_system")
  .add_system(@game_scene.game_scene_system, system_name="game_scene_system")
  .add_system(
    @game_scene.player_state_system,
    system_name="player_state_system",
  )
  .run()
}
