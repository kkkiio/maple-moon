///| Recovery HP & MP over time
pub fn new_module(
  scheduler : &@game_mod.Scheduler,
  packet_processor : @net.PacketProcessor,
  char_stats_getter : () -> @char_stats.CharStats?
) -> @game_mod.Mod {
  let delay = @utils.Duration::from_milliseconds(5000)
  scheduler.schedule_with_fixed_delay(
    fn() {
      guard let Some(char_stats) = char_stats_getter() else { None => return }
      let hp = char_stats.get_stat(@maple_stat.Id::HP)
      guard hp > 0 else { return } // dead
      // TODO: check if player is available to act
      let max_hp = char_stats.get_stat(@maple_stat.Id::MAXHP)
      // for test and fun!
      let heal_hp = @math.minimum(max_hp - hp, 77)
      let mp = char_stats.get_stat(@maple_stat.Id::MP)
      let max_mp = char_stats.get_stat(@maple_stat.Id::MAXMP)
      let heal_mp = @math.minimum(max_mp - mp, 50)
      packet_processor.send_packet(new_heal_over_time_packet(heal_hp, heal_mp))
    },
    delay,
    delay,
  )
  |> ignore
  { message_handlers: {}, actions: {}, stat_handlers: {} }
}

///|
fn new_heal_over_time_packet(hp : Int, mp : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::HEAL_OVER_TIME)
  ..write_long(0) // server don't care
  ..write_short(hp)
  ..write_short(mp)
}
