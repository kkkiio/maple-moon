struct Module {
  player_getter : () -> @player.Player?
  sp_stat_id : @char_stats.StatId
}

pub fn Module::new(
  player_getter : () -> @player.Player?,
  sp_stat_id : @char_stats.StatId
) -> Module {
  { player_getter, sp_stat_id }
}

pub fn make_handlers(
  self : Module
) -> Array[(@net.Opcode, (@net.InPacket) -> Unit)] {
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
}

pub fn make_actions(self : Module) -> Array[(@action.Id, @action.Descriptor)] {
  [
    (
      @action.Id::SKILLS,
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
            fn(skill_id, level) {
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
          ui |> @ui.Element::new
        },
      ),
    ),
  ]
}
