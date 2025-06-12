///| Display quest status icons above NPCs
///
/// Shows quest availability/completion icons above NPCs and enables quest interaction when clicking the icons
struct MapQuests {
  resource : MapQuestsResource
  quests : @map_object.MapObjects[NpcQuest]
  quests_resource : QuestResource
  npc_quests_map : Map[Int, Array[Int]]
  mut player_deps : PlayerDeps? // TODO: init on new
  network : @net.Network
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit
  get_player_deps : (@player.Player) -> PlayerDeps
}

///|
priv struct PlayerDeps {
  item_count_provider : (Int) -> Int
  char_stats_provider : () -> @char_stats.CharStats
  player_quest_log : PlayerQuestLog
}

///| Resources for MapQuests - holds icons for different quest states
struct MapQuestsResource {
  /// Icon shown when a quest is available from an NPC
  available_quest_icon : @graphics.Animation
  /// Icon shown when a quest is in progress with an NPC
  inprogress_quest_icon : @graphics.Animation
  /// Icon shown when a quest can be completed with an NPC
  completed_quest_icon : @graphics.Animation
}

///| Loads the graphical resources for quest icons
pub async fn MapQuestsResource::load() -> MapQuestsResource! {
  let ui_window_2_loader = @ui.ui_window_2_loader()
  let available_quest_icon = ui_window_2_loader.load_res_async([
    "QuestIcon", "0",
  ])
  let inprogress_quest_icon = ui_window_2_loader.load_res_async([
    "QuestIcon", "1",
  ])
  let completed_quest_icon = ui_window_2_loader.load_res_async([
    "QuestIcon", "2",
  ])
  {
    available_quest_icon: @graphics.Animation::from_resource_ex!(
      available_quest_icon,
    ),
    inprogress_quest_icon: @graphics.Animation::from_resource_ex!(
      inprogress_quest_icon,
    ),
    completed_quest_icon: @graphics.Animation::from_resource_ex!(
      completed_quest_icon,
    ),
  }
}

///|
fn MapQuests::new(
  resource : MapQuestsResource,
  quests_resource : QuestResource,
  npc_quests_map : Map[Int, Array[Int]],
  network : @net.Network,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
  get_player_deps : (@player.Player) -> PlayerDeps
) -> MapQuests {
  {
    resource,
    quests: @map_object.MapObjects::new(),
    quests_resource,
    npc_quests_map,
    player_deps: None,
    network,
    open_npc_talk_ui,
    get_player_deps,
  }
}

///|
pub fn MapQuests::set_player(self : MapQuests, player : @player.Player) -> Unit {
  self.player_deps = Some((self.get_player_deps)(player))
}

///|
pub fn MapQuests::draw(
  self : MapQuests,
  id : Int,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  self.quests.draw(id, viewx, viewy, alpha)
}

///|
pub fn MapQuests::update(self : MapQuests, physics : @physics.Physics) -> Unit {
  self.quests.update(physics)
}

///|
pub fn MapQuests::add_npc(
  self : MapQuests,
  npc_id : Int,
  npc_object : @physics.MovingObject
) -> Unit {
  guard self.player_deps
    is Some({ player_quest_log, item_count_provider, char_stats_provider }) else {
    @log.error({ "npc_id": npc_id }, "player not set yet")
    return
  }

  // Determine quest status for this NPC
  // This involves checking:
  // 1. Quests that can be started with this NPC (available quests)
  //    - Use self.quest_module.list_acceptable_quests_by_npc(player, self.quest_module.player_quest_log, npc_id)
  // 2. Quests that are in progress and involve this NPC for the current phase
  //    - Check player's started quests: self.quest_module.player_quest_log.started
  //    - See if the current phase of any started quest requires interaction with this npc_id
  // 3. Quests that can be completed with this NPC
  //    - Check player's started quests and if completion conditions for this NPC are met.

  // For simplicity, let's assume we prioritize: Completable > InProgress > Available
  let quest_ids = list_quests_by_npc(self.npc_quests_map, npc_id)
  // Check for quests that can be completed or are in progress with this NPC
  for quest_id in quest_ids {
    let stated_quest = player_quest_log.get_quest(quest_id)
    match stated_quest {
      Some(InProgress(quest)) => {
        if quest.checks.get(quest.phase) is Some(check) {
          match
            check_quest_requirements(
              check,
              item_count_provider,
              char_stats_provider,
              player_quest_log,
              quest_id,
              quest.phase,
            ) {
            Ok(_) => {
              let icon_animation = self.resource.completed_quest_icon
              self.quests.add(
                NpcQuest::new(
                  quest_id,
                  Some((quest, true)),
                  npc_id,
                  npc_object,
                  icon_animation,
                ),
              )
              return
            }
            Err(err) =>
              @log.debug(
                { "quest_id": quest_id, "error": err },
                "quest completion check failed",
              )
          }
        }
        let icon_animation = self.resource.inprogress_quest_icon
        self.quests.add(
          NpcQuest::new(
            quest_id,
            Some((quest, false)),
            npc_id,
            npc_object,
            icon_animation,
          ),
        )
        return // one quest in a time
      }
      _ => ()
    }
  }

  // Check for available quests if no completable or in-progress quest found
  if filter_acceptable_quests(
      quest_ids.iter(),
      self.quests_resource,
      item_count_provider,
      char_stats_provider,
      player_quest_log,
    ).peek()
    is Some((quest_id, _)) {
    let icon_animation = self.resource.available_quest_icon
    self.quests.add(
      NpcQuest::new(quest_id, None, npc_id, npc_object, icon_animation),
    )
    return
  }
}

///|
pub fn MapQuests::update_quest(self : MapQuests, quest_id : Int) -> Unit {
  guard self.quests.get(quest_id) is Some(npc_quest) else { return }
  self.quests.remove(quest_id)
  self.add_npc(npc_quest.npc_id, npc_quest.npc_object)
}

///|
pub fn MapQuests::remove_npc(self : MapQuests, npc_id : Int) -> Unit {
  self.quests.remove(npc_id)
}

///|
pub fn MapQuests::clear(self : MapQuests) -> Unit {
  self.quests.clear()
}

///|
pub fn MapQuests::send_cursor(
  self : MapQuests,
  pressed : Bool,
  position : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> @ui.CursorState? {
  for _, quest in self.quests {
    if quest.is_active() && quest.inrange(position, viewpos) {
      if pressed {
        guard self.quests_resource.quest_say_map.get(quest.quest_id)
          is Some(phase_says)  // must have a say
        talk_about_quest(quest, phase_says, self.network, self.open_npc_talk_ui)
        return Some(@ui.CursorState::IDLE)
      }
      return Some(@ui.CursorState::CAN_CLICK)
    }
  }
  None
}

///| Represents a quest on the current map
priv struct NpcQuest {
  npc_id : Int
  npc_object : @physics.MovingObject
  icon : @graphics.Animation
  icon_offset : @struct.Point[Int]
  quest_id : Int
  in_progress_quest : (InProgressQuest, Bool)? // (quest, is_completed)
}

///|
fn NpcQuest::new(
  quest_id : Int,
  in_progress_quest : (InProgressQuest, Bool)?,
  npc_id : Int,
  npc_object : @physics.MovingObject,
  icon : @graphics.Animation
) -> NpcQuest {
  @log.debug({ "npc_id": npc_id, "quest_id": quest_id }, "show quest icon")
  {
    quest_id,
    in_progress_quest,
    npc_id,
    npc_object,
    icon,
    icon_offset: @struct.Point::new(0, -96),
  }
}

///|
impl @map_object.MapObject for NpcQuest with get_oid(self) {
  self.quest_id
}

///|
impl @map_object.MapObject for NpcQuest with draw(self, viewx, viewy, alpha) {
  let absp = self.npc_object.get_absolute(viewx, viewy, alpha)
  let icon_pos = absp + self.icon_offset
  self.icon.draw(@graphics.DrawArgument::new(pos=icon_pos), alpha)
}

///|
impl @map_object.MapObject for NpcQuest with update(self, _) {
  self.icon.update(timestep=2) |> ignore
  7
}

///|
impl @map_object.MapObject for NpcQuest with makeactive(_self) {

}

///|
impl @map_object.MapObject for NpcQuest with is_active(_self) -> Bool {
  true
}

///|
impl @map_object.MapObject for NpcQuest with get_layer(_self) -> Int {
  7
}

///|
impl @map_object.MapObject for NpcQuest with get_position(self) -> @struct.Point[
  Int,
] {
  self.npc_object.get_position() + self.icon_offset
}

///|
fn NpcQuest::inrange(
  self : NpcQuest,
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int]
) -> Bool {
  let absp = self.get_position() + viewpos
  let dim = self.icon.get_dimensions()
  @struct.Rectangle::from4(
    absp.x - dim.x / 2,
    absp.x + dim.x / 2,
    absp.y - dim.y,
    absp.y,
  ).contains(cursorpos)
}
