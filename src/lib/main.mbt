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
pub fn game_start() -> Unit {
  entrypoint.game = @ms.Game::new() |> Some
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

///|
pub fn get_inventory_mod() -> @inventory.Module? {
  entrypoint.get_game().get_inventory_mod()
}

///|
pub fn get_skill_book_mod() -> @skill_book.Module? {
  entrypoint.get_game().get_skill_book_mod()
}

///|
pub fn get_char_stats_mod() -> @char_stats.Module? {
  entrypoint.get_game().get_char_stats_mod()
}

///|
pub fn get_keyboard_mod() -> @keyboard.Module {
  entrypoint.get_game().get_keyboard_mod()
}

///|
pub fn get_login_mod() -> @login.Module? {
  entrypoint.get_game().get_login_mod()
}
