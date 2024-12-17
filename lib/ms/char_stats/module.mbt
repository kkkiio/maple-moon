///|
struct Module {
  char_stats_getter : () -> CharStats? // TODO: manage CharStats in this module
  stat : @resource.NxNode
}

///|
pub fn Module::load(
  char_stats_getter : () -> CharStats?
) -> @utils.Future[Module] {
  @ui.ui_window_4_loader()
  .load_res(["Stat"])
  .map(fn(stat) { Module::new(char_stats_getter, stat) })
}

///|
fn Module::new(
  char_stats_getter : () -> CharStats?,
  stat : @resource.NxNode
) -> Module {
  { char_stats_getter, stat }
}

///|
pub fn make_actions(
  self : Module
) -> Map[@keyboard.ActionId, @action.Descriptor] {
  [
    (
      @keyboard.ActionId::STATS,
      @action.Descriptor::UI(
        key=@ui.UIElementType::STATS_INFO,
        focused=false,
        make_element=fn() {
          UIStatsInfo::new((self.char_stats_getter)().unwrap(), self.stat)
          |> @ui.Element::new(@ui.UIElementType::STATS_INFO)
        },
      ),
    ),
  ]
  |> Map::from_array
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, (@maple_stat.Id, @net.InPacket) -> Bool!] {
  fn handler!(stat : @maple_stat.Id, recv : @net.InPacket) {
    guard let Some(char_stats) = (self.char_stats_getter)() else {
      None => return false
    }
    let mut recalculate = false
    match stat {
      @maple_stat.Id::LEVEL =>
        // TODO: notify char_base
        // let oldlevel = self.stats.get_level()
        // if level > oldlevel {
        //   self.char_base.show_effect_id(@character.CharEffectId::LEVEL_UP)
        // }
        char_stats.set_stat(@maple_stat.LEVEL, recv.read_ubyte!())
      @maple_stat.Id::HP => {
        let current_hp = recv.read_short!()
        char_stats.set_stat(@maple_stat.Id::HP, current_hp)
        recalculate = true
        // if current_hp <= 0 {
        //   player.set_state(@character.CharState::DIED)
        //   let died = true
        //   let targetid = 0
        //   new_change_map_packet(died, targetid, "sp", false).dispatch()
        // }
      }
      @maple_stat.Id::EXP => char_stats.set_exp(recv.read_int!().to_int64())
      _ => {
        char_stats.set_stat(stat, recv.read_short!())
        recalculate = true
      }
    }
    recalculate
  }

  [
    @maple_stat.Id::LEVEL,
    @maple_stat.Id::STR,
    @maple_stat.Id::DEX,
    @maple_stat.Id::INT,
    @maple_stat.Id::LUK,
    @maple_stat.Id::HP,
    @maple_stat.Id::MAXHP,
    @maple_stat.Id::MP,
    @maple_stat.Id::MAXMP,
    @maple_stat.Id::AP,
    @maple_stat.Id::SP,
    @maple_stat.Id::EXP,
    @maple_stat.Id::FAME,
  ]
  .iter()
  .map(fn(stat_id) { (stat_id, handler) })
  |> Map::from_iter
}
