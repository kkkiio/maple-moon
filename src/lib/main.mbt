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
pub fn game_start() -> @js.Value {
  let game = @ms.Game::new()
  entrypoint.game = game |> Some
  @js.Value::cast_from(game)
}

///|
pub fn game_update(time : Double) -> Unit {
  entrypoint.get_game().update(time |> @utils.TimePoint::from_micro)
}

///|
pub fn onmousemove(x : Int, y : Int) -> Unit {
  entrypoint.get_game().get_window().onmousemove(x, y)
}

///|
pub fn onmousedown() -> Unit {
  entrypoint.get_game().get_window().onmousedown()
}

///|
pub fn onmouseup() -> Unit {
  entrypoint.get_game().get_window().onmouseup()
}

///|
pub fn onkeydown(key : String) -> Unit {
  entrypoint.get_game().get_window().key_callback(key, true)
}

///|
pub fn onkeyup(key : String) -> Unit {
  entrypoint.get_game().get_window().key_callback(key, false)
}
