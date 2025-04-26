///|
typealias StatChangeListener = (Int, Int) -> Bool

///|
pub fn watch_player_char_stat(
  mod : Module,
  stat_id : String,
  listener : StatChangeListener
) -> Unit {
  let stat_id = match stat_id {
    "skin" => @maple_stat.Id::SKIN
    "face" => @maple_stat.Id::FACE
    "hair" => @maple_stat.Id::HAIR
    "level" => @maple_stat.Id::LEVEL
    "job" => @maple_stat.Id::JOB
    "str" => @maple_stat.Id::STR
    "dex" => @maple_stat.Id::DEX
    "int" => @maple_stat.Id::INT
    "luk" => @maple_stat.Id::LUK
    "hp" => @maple_stat.Id::HP
    "maxhp" => @maple_stat.Id::MAXHP
    "mp" => @maple_stat.Id::MP
    "maxmp" => @maple_stat.Id::MAXMP
    "ap" => @maple_stat.Id::AP
    "sp" => @maple_stat.Id::SP
    "exp" => @maple_stat.Id::EXP
    "fame" => @maple_stat.Id::FAME
    "meso" => @maple_stat.Id::MESO
    "pet" => @maple_stat.Id::PET
    "gacha_exp" => @maple_stat.Id::GACHAEXP
    _ => {
      @log.error({ "stat_id": stat_id }, "watch_stat") // TODO: raise error
      return
    }
  }
  match mod.player_char_stats {
    Some(stats) => {
      let value = stats.get_stat(stat_id)
      let cont = listener(value, value)
      if not(cont) {
        return
      }
    }
    None => ()
  }
  let listeners = mod.stat_listeners.get_or_init(stat_id, fn() { Array::new() })
  listeners.push(fn(old_value, new_value) {
    match listener(old_value, new_value) {
      true => IterResult::IterContinue
      false => IterResult::IterEnd
    }
  })
}

///|
fn spend_ap(mod : Module, stat_id : @maple_stat.Id) -> Unit {
  mod.network.send_message({ stat: stat_id })
}

///|
fn get_recommend_assign(mod : Module) -> Assign {
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
struct Assign {
  str : Int
  dex : Int
  int : Int
  luk : Int
} derive(Default)
