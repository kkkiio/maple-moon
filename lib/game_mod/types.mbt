///|
pub(all) struct Mod {
  message_handlers : Map[@net.Opcode, (@net.InPacket) -> Unit]
  actions : Map[@keyboard.ActionId, @action.Descriptor]
  stat_handlers : Map[@maple_stat.Id, StatHandler]
}

///|
pub(all) struct StatHandler {
  parse_fn : (@net.InPacket) -> Int!
  update_fn : (Int) -> Bool
}

///|
pub(open) trait Scheduler {
  schedule_with_fixed_delay(Self, () -> Unit, @utils.Duration, @utils.Duration) ->
       () -> Unit
}
