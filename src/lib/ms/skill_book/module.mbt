///|
struct Module {
  player_getter : () -> @player.Player?
  mut player_skill_book : (SkillBook, Ref[Bool])?
  watchers : Array[SkillBookWatcher]
  combat : @combat_system.Combat
  inventory : @inventory.Inventory
}

///|
pub async fn Module::load(
  player_getter : () -> @player.Player?,
  combat : @combat_system.Combat,
  inventory : @inventory.Inventory,
) -> Module noraise {
  // let skill_book_resource = @ui.ui_window_2_loader().load_resource(["Skill"])
  Module::new(player_getter, combat, inventory)
}

///|
fn Module::new(
  player_getter : () -> @player.Player?,
  combat : @combat_system.Combat,
  inventory : @inventory.Inventory,
) -> Module {
  { player_getter, player_skill_book: None, watchers: [], combat, inventory }
}

///|

///|
// pub fn Module::make_actions(
//   _ : Module,
// ) -> Map[BasicActionId, @action.Descriptor] {
// [
//   (
//     ActionId::SKILLS,
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
// }

///|
pub async fn Module::load_player_skill_book(
  self : Module,
  job : @job.Job,
) -> &@legacy_types.SkillBook {
  let skill_book = SkillBook::load(job, self.watchers)
  if self.player_skill_book is Some((_, cont_listen)) {
    cont_listen.val = false // dispose
  }
  let cont_listen = Ref::new(true)
  self.player_skill_book = Some((skill_book, cont_listen))
  skill_book
}
