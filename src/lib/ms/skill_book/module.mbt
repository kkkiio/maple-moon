///|
struct Module {
  player_getter : () -> @player.Player?
  packet_processor : @net.Network
  mut skill_book : SkillBook?
  watchers : Array[SkillBookWatcher]
  string_loader : @resource.SyncLoader
  io_service : @io_task.IOService
}

///|
pub async fn Module::load(
  player_getter : () -> @player.Player?,
  packet_processor : @net.Network,
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService
) -> Module {
  // let skill_book_resource = @ui.ui_window_2_loader().load_resource(["Skill"])
  Module::new(player_getter, packet_processor, string_loader, io_service)
}

///|
fn Module::new(
  player_getter : () -> @player.Player?,
  packet_processor : @net.Network,
  string_loader : @resource.SyncLoader,
  io_service : @io_task.IOService
) -> Module {
  {
    player_getter,
    packet_processor,
    skill_book: None,
    watchers: [],
    string_loader,
    io_service,
  }
}

///|
pub fn make_handlers(
  self : Module
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    @net.make_handler(@net.UPDATE_SKILL, parse_skill_update, fn(
      update : SkillUpdate
    ) {
      handle_skill_update(self.player_getter, update)
    }),
  ]
  |> Map::from_array
}

///|
pub fn Module::make_actions(
  _ : Module
) -> Map[@keyboard.BasicActionId, @action.Descriptor] {
  // [
  //   (
  //     @keyboard.ActionId::SKILLS,
  //     @action.Descriptor::UI(key=@ui.UIElementType::SKILL_BOOK, focused=false, make_element=fn(

  //     ) {
  //       let player = (self.player_getter)().unwrap()
  //       let stats = player.get_stats()
  //       let skillbook = player.get_skills()
  //       @ui.Element::new(
  //         fn(hooks) {
  //           let ui = SkillBookUI::new(
  //             {
  //               skillbook,
  //               job: stats.get_job(),
  //               level: stats.get_stat(@maple_stat.Id::LEVEL),
  //               sp: stats.get_stat(@maple_stat.Id::SP),
  //             },
  //             self.skill,
  //             hooks,
  //           )
  //           stats.watch_stat_changes(@maple_stat.Id::SP, fn(_old, sp) {
  //             guard ui.get_ui_model().active else { return IterEnd }
  //             ui.set_attributes({
  //               skillbook: player.get_skills(),
  //               job: stats.get_job(),
  //               level: stats.get_stat(@maple_stat.Id::LEVEL),
  //               sp,
  //             })
  //             IterContinue
  //           })
  //           skillbook.listen_skill_level_changes(fn(_skill_id, _level) { // TODO: fine-granular update
  //             guard ui.get_ui_model().active else { return IterEnd }
  //             ui.set_attributes({
  //               skillbook,
  //               job: stats.get_job(),
  //               level: stats.get_stat(@maple_stat.Id::LEVEL),
  //               sp: stats.get_stat(@maple_stat.Id::SP),
  //             })
  //             IterContinue
  //           })
  //           ui
  //         },
  //         @ui.UIElementType::SKILL_BOOK,
  //       )
  //     }),
  //   ),
  // ]
  // |> Map::from_array
  {}
}

///|
pub fn Module::load_skill_book(
  self : Module,
  job : @job.Job
) -> @utils.Future[&@player.SkillBook] {
  SkillBook::load(self.string_loader, self.io_service, job, self.watchers)
  .tap(fn(skill_book) { self.skill_book = Some(skill_book) })
  .map(fn(skill_book) { skill_book })
}
