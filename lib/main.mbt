///|
struct EntryPoint {
  mut game : @ms.Game?
}

///|
let entrypoint : EntryPoint = { game: None }

///|
pub fn game_start() -> Unit {
  entrypoint.game = @ms.Game::new() |> Some
}

///|
pub fn game_update(time : Double) -> Unit {
  entrypoint.game.unwrap().update(time |> @utils.TimePoint::from_micro)
}

///|
pub fn onmousemove(x : Int, y : Int) -> Unit {
  entrypoint.game.unwrap().get_window().onmousemove(x, y)
}

///|
pub fn onmousedown() -> Unit {
  entrypoint.game.unwrap().get_window().onmousedown()
}

///|
pub fn onmouseup() -> Unit {
  entrypoint.game.unwrap().get_window().onmouseup()
}

///|
pub fn onkeydown(key : String) -> Unit {
  entrypoint.game.unwrap().get_window().key_callback(key, true)
}

///|
pub fn onkeyup(key : String) -> Unit {
  entrypoint.game.unwrap().get_window().key_callback(key, false)
}

///|
pub fn get_all_inventory_items_by_type(t : Int) -> Array[@inventory.ItemUIData] {
  entrypoint.game
  .unwrap()
  .get_inventory_mod()
  .map(fn(it) {
    @inventory.get_all_items_by_type(
      it,
      @inventory.TypeId::by_value(t).unwrap(),
    )
  })
  .or(Array::new())
}

///|
pub fn get_skill_book_mod() -> @skill_book.Module? {
  entrypoint.game.unwrap().get_skill_book_mod()
}

///|
pub fn get_char_stats_mod() -> @char_stats.Module? {
  entrypoint.game.unwrap().get_char_stats_mod()
}
