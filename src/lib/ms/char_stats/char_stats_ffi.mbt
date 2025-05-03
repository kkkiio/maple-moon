///|
typealias StatChangeListener = (Int, Int) -> Bool

///|
pub fn watch_player_char_stat(
  mod : Module,
  stat_name : String,
  listener : StatChangeListener
) -> Unit {
  guard @maple_stat.Id::from_name(stat_name) is Some(stat) else {
    @log.error({ "stat_name": stat_name }, "unrecognized stat_name")
    return
  }
  match mod.player_char_stats {
    Some(stats) => {
      let value = stats.get_stat(stat)
      let cont = listener(value, value)
      if not(cont) {
        return
      }
    }
    None => ()
  }
  let listeners = mod.stat_listeners.get_or_init(stat, fn() { Array::new() })
  listeners.push(fn(old_value, new_value) {
    match listener(old_value, new_value) {
      true => IterResult::IterContinue
      false => IterResult::IterEnd
    }
  })
}

///|
pub fn watch_player_total_stat(
  mod : Module,
  stat_name : String,
  listener : StatChangeListener
) -> Unit {
  guard @maple_stat.EquipStatId::from_name(stat_name) is Some(stat) else {
    @log.error({ "stat_name": stat_name }, "unrecognized stat_name")
    return
  }
  match mod.player_char_stats {
    Some(stats) => {
      let value = stats.get_total(stat)
      let cont = listener(value, value)
      if not(cont) {
        return
      }
    }
    None => ()
  }
  let listeners = mod.total_listeners.get_or_init(stat, fn() { Array::new() })
  listeners.push(fn(old_value, new_value) { listener(old_value, new_value) })
}

///|
pub fn spend_ap(mod : Module, stat_name : String) -> Unit {
  guard @maple_stat.Id::from_name(stat_name) is Some(stat) else {
    @log.error({ "stat_name": stat_name }, "unrecognized stat_name")
    return
  }
  mod.network.send_message({ stat, })
}

///|
pub fn get_recommend_assign(mod : Module) -> Assign {
  let nowap = mod.player_char_stats.map_or(0, fn(stats) {
    stats.get_stat(@maple_stat.Id::AP)
  })
  let assign = Assign::default()
  guard mod.player_char_stats is Some(char_stats) else { return assign }
  let job = char_stats.job
  let weapon_type = (char_stats.weapon_type_getter)()
  // 4/5 primary + 1/5 secondary
  let secondary = nowap / 5
  let primary = nowap - secondary
  let assign = match job.get_primary(weapon_type) {
    @maple_stat.EquipStatId::STR => { ..assign, str: primary }
    @maple_stat.EquipStatId::DEX => { ..assign, dex: primary }
    @maple_stat.EquipStatId::INT => { ..assign, int: primary }
    @maple_stat.EquipStatId::LUK => { ..assign, luk: primary }
    _ => assign
  }
  let assign = match job.get_secondary(weapon_type) {
    @maple_stat.EquipStatId::STR => { ..assign, str: secondary }
    @maple_stat.EquipStatId::DEX => { ..assign, dex: secondary }
    @maple_stat.EquipStatId::INT => { ..assign, int: secondary }
    @maple_stat.EquipStatId::LUK => { ..assign, luk: secondary }
    _ => assign
  }
  return assign
}

///|
pub struct Assign {
  str : Int
  dex : Int
  int : Int
  luk : Int
} derive(Default)

///|
priv struct SpendAPMessage {
  stat : @maple_stat.Id
} derive(Show)

///|
impl @net.OutMessage for SpendAPMessage with pack(self) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SPEND_AP)
  ..write_time()
  ..write_int(self.stat.int_value())
}
