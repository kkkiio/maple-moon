///| Display quest status icons above NPCs
///
/// Shows quest availability/completion icons above NPCs and enables quest interaction when clicking the icons
struct MapQuests {
  resource : MapQuestsResource
  quests : @map_object.MapObjects[NpcQuest]
  quests_resource : QuestResource
  player_quest_log : PlayerQuestLog
  npc_quests_map : Map[Int, Array[Int]]
  mut player : @player.Player? // TODO: init on new
}

///| Resources for MapQuests - holds icons for different quest states
struct MapQuestsResource {
  // Icon shown when a quest is available from an NPC
  available_quest_icon : @graphics.Animation
  // Icon shown when a quest is in progress with an NPC (optional, could be same as available or a different one)
  inprogress_quest_icon : @graphics.Animation
  // Icon shown when a quest can be completed with an NPC
  completed_quest_icon : @graphics.Animation
}

///| Loads the graphical resources for quest icons
pub fn MapQuestsResource::load() ->
     @utils.Future[Result[MapQuestsResource, Error]] {
  let ui_window_2_loader = @ui.ui_window_2_loader()
  let available_quest_icon_fut = ui_window_2_loader.load_res(["QuestIcon", "0"])
  let inprogress_quest_icon_fut = ui_window_2_loader.load_res(["QuestIcon", "1"])
  let completed_quest_icon_fut = ui_window_2_loader.load_res(["QuestIcon", "2"])
  @utils.Future::combine3(
    available_quest_icon_fut, inprogress_quest_icon_fut, completed_quest_icon_fut,
  ).map_exn(fn(res) {
    let (available_node, inprogress_node, completed_node) = res
    {
      available_quest_icon: @graphics.Animation::from_resource_ex!(
        available_node,
      ),
      inprogress_quest_icon: @graphics.Animation::from_resource_ex!(
        inprogress_node,
      ),
      completed_quest_icon: @graphics.Animation::from_resource_ex!(
        completed_node,
      ),
    }
  })
}

///|
fn MapQuests::new(
  resource : MapQuestsResource,
  quests_resource : QuestResource,
  player_quest_log : PlayerQuestLog,
  npc_quests_map : Map[Int, Array[Int]]
) -> MapQuests {
  {
    resource,
    quests: @map_object.MapObjects::new(),
    quests_resource,
    player_quest_log,
    npc_quests_map,
    player: None,
  }
}

///|
pub fn MapQuests::set_player(self : MapQuests, player : @player.Player) -> Unit {
  self.player = Some(player)
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
  guard self.player is Some(player) else {
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

  // For simplicity, let's assume we prioritize: Completable > Available > InProgress
  let quest_ids = list_quests_by_npc(self.npc_quests_map, npc_id)
  @log.info({ "quest_ids": quest_ids, "npc_id": npc_id }, "list_quests_by_npc")
  // Check for completable quests
  for quest_id in quest_ids {
    let status = self.player_quest_log.get_quest(quest_id)
    match status {
      Some(Completed(_)) => {
        let icon_animation = self.resource.completed_quest_icon
        self.quests.add(
          NpcQuest::new(quest_id, npc_id, npc_object, icon_animation),
        )
        return
      }
      _ => ()
    }
  }

  // Check for available quests if no completable quest found
  if filter_acceptable_quests(
      quest_ids.iter(),
      self.quests_resource,
      player,
      self.player_quest_log,
    ).peek()
    is Some((quest_id, _)) {
    let icon_animation = self.resource.available_quest_icon
    self.quests.add(NpcQuest::new(quest_id, npc_id, npc_object, icon_animation))
    return
  }

  // Check for in-progress quests if no available/completable found
  for quest_id in quest_ids {
    let status = self.player_quest_log.get_quest(quest_id)
    match status {
      Some(InProgress(quest)) =>
        if quest.checks.get(0).map_or(false, fn(it) { it.npc == Some(npc_id) }) {
          let icon_animation = self.resource.inprogress_quest_icon
          self.quests.add(
            NpcQuest::new(quest_id, npc_id, npc_object, icon_animation),
          )
          return
        }
      _ => ()
    }
  }
}

///|
pub fn MapQuests::remove_npc(self : MapQuests, npc_id : Int) -> Unit {
  self.quests.remove(npc_id)
}

///|
pub fn MapQuests::clear(self : MapQuests) -> Unit {
  self.quests.clear()
}

///| Represents a quest on the current map
priv struct NpcQuest {
  npc_id : Int
  npc_object : @physics.MovingObject
  icon : @graphics.Animation
  icon_offset : @struct.Point[Int]
}

///|
fn NpcQuest::new(
  quest_id : Int,
  npc_id : Int,
  npc_object : @physics.MovingObject,
  icon : @graphics.Animation
) -> NpcQuest {
  @log.debug({ "npc_id": npc_id, "quest_id": quest_id }, "show quest icon")
  { npc_id, npc_object, icon, icon_offset: @struct.Point::new(0, -80) }
}

///|
impl @map_object.MapObject for NpcQuest with get_oid(self) {
  self.npc_id
}

///|
impl @map_object.MapObject for NpcQuest with draw(self, viewx, viewy, alpha) {
  let absp = self.npc_object.get_absolute(viewx, viewy, alpha)
  let icon_pos = absp + self.icon_offset
  self.icon.draw(@graphics.DrawArgument::new(pos=icon_pos), alpha)
}

///|
impl @map_object.MapObject for NpcQuest with update(self, _) {
  self.icon.update(timestep=4) |> ignore
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
typealias Point = @struct.Point[Int]
