struct EntryPoint {
  mut game : @utils.Future[@ms.Game]
}

let entrypoint : EntryPoint = { game: @utils.Future::never() }

pub fn game_start() -> Unit {
  entrypoint.game = @ms.Game::load()
}

pub fn game_update(time : Double) -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.on_draw(time |> @utils.TimePoint::from_micro)
}

pub fn onmousemove(x : Int, y : Int) -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.get_window().onmousemove(x, y)
}

pub fn onmousedown() -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.get_window().onmousedown()
}

pub fn onmouseup() -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.get_window().onmouseup()
}

pub fn onkeydown(key : String) -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.get_window().key_callback(key, true)
}

pub fn onkeyup(key : String) -> Unit {
  guard let Some(game) = entrypoint.game.poll() else { None => return  }
  game.get_window().key_callback(key, false)
}
