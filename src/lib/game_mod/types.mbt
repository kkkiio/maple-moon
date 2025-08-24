///|
pub(all) struct Mod {
  message_handlers : Map[@net.Opcode, (@net.InPacket) -> Unit]
  actions : Map[@keyboard.BasicActionId, @action.Descriptor]
  stat_handlers : Map[@maple_stat.Id, StatHandler]
}

///|
pub typealias (Int) -> Bool as StatHandler

///|
pub typealias (@net.InPacket) -> &SubRouteAction raise as SubRouteHandler

///|
pub(open) trait SubRouteAction: Show {
  handle(Self) -> Unit
}

///|
pub(open) trait Scheduler {
  schedule_with_fixed_delay(Self, () -> Unit, @utils.Duration, @utils.Duration) -> () -> Unit
}
