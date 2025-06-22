///| Recovery HP & MP over time
pub fn new_module(
  scheduler : &@game_mod.Scheduler,
  packet_processor : @net.Network,
  char_stats_getter : () -> @char_stats.CharStats?
) -> @game_mod.Mod {
  let delay = @utils.Duration::from_milliseconds(5000)
  scheduler.schedule_with_fixed_delay(
    fn() {
      guard char_stats_getter() is Some(char_stats) else { return }
      let hp = char_stats.get_stat(@maple_stat.Id::HP)
      guard hp > 0 else { return } // dead
      // TODO: check if player is available to act
      let max_hp = char_stats.get_stat(@maple_stat.Id::MAXHP)
      // skip sit check for test and fun!
      let heal_hp = (max_hp - hp) |> @math.minimum(77) |> @math.maximum(0)
      let mp = char_stats.get_stat(@maple_stat.Id::MP)
      let max_mp = char_stats.get_stat(@maple_stat.Id::MAXMP)
      let heal_mp = (max_mp - mp) |> @math.minimum(50) |> @math.maximum(0)
      guard heal_hp > 0 || heal_mp > 0 else { return }
      packet_processor.send_message({ hp: heal_hp, mp: heal_mp })
    },
    delay,
    delay,
  )
  |> ignore
  { message_handlers: {}, actions: {}, stat_handlers: {} }
}

///|
priv struct HealOverTimeMessage {
  hp : Int
  mp : Int
} derive(ToJson, Show)

///|
impl @net.OutMessage for HealOverTimeMessage with pack(self) {
  @net.OutPacket::new(@net.ClientOpcode::HEAL_OVER_TIME)
  ..write_long(0) // server doesn't care
  ..write_short(self.hp)
  ..write_short(self.mp)
}
