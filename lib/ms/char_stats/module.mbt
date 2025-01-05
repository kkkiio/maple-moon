///|
struct Module {
  player_char_stats_getter : () -> CharStats? // TODO: manage CharStats in this module
  stat : @resource.NxNode
}

///|
pub fn Module::load(
  player_char_stats_getter : () -> CharStats?
) -> @utils.Future[Module] {
  @ui.ui_window_4_loader()
  .load_res(["Stat"])
  .map(fn(stat) { Module::new(player_char_stats_getter, stat) })
}

///|
fn Module::new(
  player_char_stats_getter : () -> CharStats?,
  stat : @resource.NxNode
) -> Module {
  { player_char_stats_getter, stat }
}

///|
pub fn make_actions(
  self : Module
) -> Map[@keyboard.ActionId, @action.Descriptor] {
  [
    (
      @keyboard.ActionId::STATS,
      @action.Descriptor::UI(key=@ui.UIElementType::STATS_INFO, focused=false, make_element=fn(

      ) {
        @ui.Element::new(
          fn(hooks) {
            UIStatsInfo::new(
              (self.player_char_stats_getter)().unwrap(),
              self.stat,
              hooks,
            )
          },
          @ui.UIElementType::STATS_INFO,
        )
      }),
    ),
  ]
  |> Map::from_array
}

///|
pub fn make_stat_handlers(
  self : Module
) -> Map[@maple_stat.Id, @game_mod.StatHandler] {
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
  .map(fn(stat_id) {
    (
      stat_id,
      fn(value) {
        guard let Some(char_stats) = (self.player_char_stats_getter)() else {
          None => return false
        }
        match stat_id {
          @maple_stat.Id::LEVEL => {
            char_stats.set_stat(@maple_stat.Id::LEVEL, value)
            false
          }
          @maple_stat.Id::EXP => {
            char_stats.set_exp(value.to_int64())
            false
          }
          _ => {
            char_stats.set_stat(stat_id, value)
            true
          }
        }
      },
    )
  })
  |> Map::from_iter
}
