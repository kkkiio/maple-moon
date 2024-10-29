struct Module {} derive(Default)

pub fn Module::new() -> Module {
  Module::default()
}

pub fn make_handlers(
  self : Module,
  player_getter : () -> @player.Player?
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
  [
    (
      @net.UPDATE_SKILL,
      @net.with_log(
        @net.UPDATE_SKILL,
        fn(recv : @net.InPacket) { handle_update_skill!(player_getter, recv) }
      )
    )
  ]
}
