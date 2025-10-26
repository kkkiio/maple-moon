///|
priv struct EntryPoint {
  mut game : @ms.Game?
}

///|
let entrypoint : EntryPoint = { game: None }

///|
fn EntryPoint::get_game(self : EntryPoint) -> @ms.Game {
  return self.game.unwrap()
}

///|
fn game_start(_backend : &@system.Backend) -> Unit {
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
pub fn game_update(time : Double) -> Unit {
  entrypoint.get_game().update(time |> @utils.TimePoint::from_micro)
}

///|
pub fn onkeydown(key : String) -> Unit {
  guard entrypoint.get_game().get_window() is Some(window) else { return }
  window.key_callback(key, true)
}

///|
pub fn onkeyup(key : String) -> Unit {
  guard entrypoint.get_game().get_window() is Some(window) else { return }
  window.key_callback(key, false)
}

///|
fn main {
  @system.App::new(
    @canvas.CanvasBackend::new().with_cross_origin(Some("anonymous")),
  )
  .with_canvas_width(@config.constants.get_viewwidth() |> Double::from_int)
  .with_canvas_height(@config.constants.get_viewheight() |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  // .add_plugin(@plugins.debug_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(@login.select_char_system, system_name="select_char_system")
  .add_system(@game_scene.game_scene_system, system_name="game_scene_system")
  .run()
}
