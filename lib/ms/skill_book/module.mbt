///|
struct Module {
  player_getter : () -> @player.Player?
  sp_stat_id : @char_stats.StatId
  skill : @resource.NxNode
}

///|
pub fn Module::load(
  player_getter : () -> @player.Player?,
  sp_stat_id : @char_stats.StatId
) -> @utils.Future[Module] {
  @ui.ui_window_2_loader().load_res(["Skill"])
  |> @utils.map(fn(skill) { Module::new(player_getter, sp_stat_id, skill) })
}

///|
fn Module::new(
  player_getter : () -> @player.Player?,
  sp_stat_id : @char_stats.StatId,
  skill : @resource.NxNode
) -> Module {
  { player_getter, sp_stat_id, skill }
}

///|
pub fn make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      @net.UPDATE_SKILL,
      @net.with_log(
        @net.UPDATE_SKILL,
        fn(recv : @net.InPacket) {
          handle_update_skill!(self.player_getter, recv)
        },
      ),
    ),
  ]
  |> Map::from_array
}

///|
pub fn make_actions(
  self : Module
) -> Map[@keyboard.ActionId, @action.Descriptor] {
  [
    (
      @keyboard.ActionId::SKILLS,
      @action.Descriptor::UI(
        key=@ui.UIElementType::SKILL_BOOK,
        focused=false,
        make_element=fn() {
          let player = (self.player_getter)().unwrap()
          let stats = player.get_stats()
          let skillbook = player.get_skills()
          let ui = SkillBookUI::new(
            {
              skillbook,
              job: stats.get_job(),
              level: stats.get_level(),
              sp: stats.get_sp(),
            },
            self.skill,
          )
          stats.listen_stat_changes(
            self.sp_stat_id,
            fn(sp) {
              guard ui.get_ui_model().active else { return false }
              ui.set_attributes(
                {
                  skillbook: player.get_skills(),
                  job: stats.get_job(),
                  level: stats.get_level(),
                  sp,
                },
              )
              true
            },
          )
          skillbook.listen_skill_level_changes(
            fn(_skill_id, _level) { // TODO: fine-granular update
              guard ui.get_ui_model().active else { return false }
              ui.set_attributes(
                {
                  skillbook,
                  job: stats.get_job(),
                  level: stats.get_level(),
                  sp: stats.get_sp(),
                },
              )
              true
            },
          )
          ui |> @ui.Element::new(@ui.UIElementType::SKILL_BOOK)
        },
      ),
    ),
  ]
  |> Map::from_array
}
