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
