struct Module {} derive(Default)

pub fn Module::new() -> Module {
  Module::default()
}

pub fn make_handlers(
  self : Module,
  player_getter : () -> @player.Player?
) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [(@net.UPDATE_SKILL, UpdateSkillHandler::new(player_getter))]
}
