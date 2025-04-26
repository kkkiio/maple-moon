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
    @equip_stat.Id::STR => { ..assign, str: primary }
    @equip_stat.Id::DEX => { ..assign, dex: primary }
    @equip_stat.Id::INT => { ..assign, int: primary }
    @equip_stat.Id::LUK => { ..assign, luk: primary }
    _ => assign
  }
  let assign = match job.get_secondary(weapon_type) {
    @equip_stat.Id::STR => { ..assign, str: secondary }
    @equip_stat.Id::DEX => { ..assign, dex: secondary }
    @equip_stat.Id::INT => { ..assign, int: secondary }
    @equip_stat.Id::LUK => { ..assign, luk: secondary }
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
