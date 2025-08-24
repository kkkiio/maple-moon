///|
pub fn get_module(game : @ms.Game, name : String) -> @js.Nullable[@js.Value] {
  let opt = match name {
    "inventory" =>
      game.get_inventory_mod().map(fn(it) { @js.Value::cast_from(it) })
    "skill_book" =>
      game.get_skill_book_mod().map(fn(it) { @js.Value::cast_from(it) })
    "char_stats" =>
      game.get_char_stats_mod().map(fn(it) { @js.Value::cast_from(it) })
    "keyboard" => @js.Value::cast_from(game.get_keyboard_mod()) |> Some
    "login" => game.get_login_mod().map(fn(it) { @js.Value::cast_from(it) })
    "stage" => game.get_stage().map(fn(it) { @js.Value::cast_from(it) })
    "shop" => game.get_shop_mod().map(fn(it) { @js.Value::cast_from(it) })
    "quest" => game.get_quest_mod().map(fn(it) { @js.Value::cast_from(it) })
    _ => {
      @log.error({ "name": name }, "Unknown module")
      panic()
    }
  }
  opt |> @js.Nullable::from_option
}
