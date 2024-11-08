struct Module {
  char_stats_getter : () -> CharStats? // TODO: manage CharStats in this module
}

pub fn Module::new(char_stats_getter : () -> CharStats?) -> Module {
  { char_stats_getter, }
}

pub fn make_actions(self : Module) -> Array[(@action.Id, @action.Descriptor)] {
  [
    (
      @action.Id::STATS,
      @action.Descriptor::UI(
        key=@ui.UIElementType::STATS_INFO,
        focused=false,
        make_element=fn() {
          UIStatsInfo::load((self.char_stats_getter)().unwrap())
          |> @ui.Element::new
        },
      ),
    ),
  ]
}
