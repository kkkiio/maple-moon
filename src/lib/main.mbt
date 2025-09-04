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
let all_codes : @set.Set[@system.Code] = @set.Set::from_array([
  KeyA,
  KeyB,
  KeyC,
  KeyD,
  KeyE,
  KeyF,
  KeyG,
  KeyH,
  KeyI,
  KeyJ,
  KeyK,
  KeyL,
  KeyM,
  KeyN,
  KeyO,
  KeyP,
  KeyQ,
  KeyR,
  KeyS,
  KeyT,
  KeyU,
  KeyV,
  KeyW,
  KeyX,
  KeyY,
  KeyZ,
  ArrowUp,
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  Space,
  Enter,
  Escape,
])

///|
fn to_html_key(code : @system.Code) -> String {
  match code {
    ArrowUp => @keyboard.arrowUp
    ArrowDown => @keyboard.arrowDown
    ArrowLeft => @keyboard.arrowLeft
    ArrowRight => @keyboard.arrowRight
    Space => @keyboard.space
    Enter => @keyboard.enter
    KeyB => @keyboard.keyB
    KeyA => @keyboard.keyA
    KeyC => @keyboard.keyC
    KeyD => @keyboard.keyD
    KeyE => @keyboard.keyE
    KeyF => @keyboard.keyF
    KeyG => @keyboard.keyG
    KeyH => @keyboard.keyH
    KeyI => @keyboard.keyI
    KeyJ => @keyboard.keyJ
    KeyK => @keyboard.keyK
    KeyL => @keyboard.keyL
    KeyM => @keyboard.keyM
    KeyN => @keyboard.keyN
    KeyO => @keyboard.keyO
    KeyP => @keyboard.keyP
    KeyQ => @keyboard.keyQ
    KeyR => @keyboard.keyR
    KeyS => @keyboard.keyS
    KeyT => @keyboard.keyT
    KeyU => @keyboard.keyU
    KeyV => @keyboard.keyV
    KeyW => @keyboard.keyW
    KeyX => @keyboard.keyX
    KeyY => @keyboard.keyY
    KeyZ => @keyboard.keyZ
    Escape => @keyboard.escape
  }
}

///|
fn player_state_system(_backend : &@system.Backend) -> Unit {
  for code in all_codes {
    if @system.is_just_pressed(code) {
      onkeydown(to_html_key(code))
    }
    if @system.is_just_released(code) {
      onkeyup(to_html_key(code))
    }
  }
}

///|
fn main {
  @log.info({ "msg": "main" }, "main")
  @system.App::new(
    @canvas.CanvasBackend::new().with_cross_origin(Some("anonymous")),
  )
  .with_canvas_width(@config.constants.get_viewwidth() |> Double::from_int)
  .with_canvas_height(@config.constants.get_viewheight() |> Double::from_int)
  .with_fps(@graphics.fps)
  .add_plugin(@plugins.default_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(player_state_system, system_name="player_state_system")
  .add_system(@cursor.cursor_system, system_name="cursor_system")
  .add_system(@login.select_char_system, system_name="select_char_system")
  .run()
}
