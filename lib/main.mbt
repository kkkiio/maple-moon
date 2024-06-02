struct EntryPoint {
  mut game : Option[@ms.Game]
}

let entrypoint : EntryPoint = { game: None }

pub fn start(g : @ms.Gl_g, nowMicro : Int64) -> Unit {
  entrypoint.game = Some(@ms.Game::start(g, nowMicro))
}
