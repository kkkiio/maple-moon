struct EntryPoint {
  mut game : @ms.Game?
}

let entrypoint : EntryPoint = { game: None }

pub fn game_start() -> Unit {
  entrypoint.game = Some(@ms.Game::start())
}

pub fn game_update(time : Double) -> Unit {
  entrypoint.game.unwrap().on_draw(time |> @utils.TimePoint::from_micro)
}

pub fn onmousemove(x : Int, y : Int) -> Unit {
  @ms.Window::get().onmousemove(x, y)
}

pub fn onmousedown() -> Unit {
  @ms.Window::get().onmousedown()
}

pub fn onmouseup() -> Unit {
  @ms.Window::get().onmouseup()
}

pub fn onkeydown(key : String) -> Unit {
  @ms.Window::get().key_callback(key, true)
}

pub fn onkeyup(key : String) -> Unit {
  @ms.Window::get().key_callback(key, false)
}
