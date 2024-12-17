///| Recovery HP & MP over time
pub fn new_module(
  scheduler : &@game_mod.Scheduler,
  packet_processor : @net.PacketProcessor,
  char_stats_getter : () -> @char_stats.CharStats?
) -> @game_mod.Mod {
  let delay = @utils.Duration::from_milliseconds(2000)
  scheduler.schedule_with_fixed_delay(
    fn() {
      guard let Some(char_stats) = char_stats_getter() else { None => return }
      guard char_stats.get_stat(@maple_stat.Id::HP) > 0 else { return }
      packet_processor.send_packet(new_heal_over_time_packet())
    },
    delay,
    delay,
  )
  |> ignore
  { message_handlers: {}, actions: {}, stat_handlers: {} }
}

///|
fn new_heal_over_time_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::HEAL_OVER_TIME)
  ..write_long(0) // server don't care
  ..write_short(77) // for test and fun!
  ..write_short(100) // for test and fun!
}
