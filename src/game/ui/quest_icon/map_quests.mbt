///|
using @quest {type PlayerQuestLog}

///|
/// Display quest status icons above NPCs.
///
/// Shows quest availability/completion icons above NPCs and enables quest
/// interaction when clicking the icons.
struct MapQuests {
  resource : MapQuestsResource
  quests_resource : QuestResource
  npc_quests_map : Map[Int, Array[Int]]
  mut player_deps : PlayerDeps?
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit
  get_player_deps : (@player.Player) -> PlayerDeps
  npc_to_icon_entity : Map[Int, @entity.Entity]
  quest_to_npc_id : Map[Int, Int]
  npc_runtime : Map[Int, NpcQuestRuntime]
}

///|
pub(all) enum QuestIconState {
  /// Quest can be accepted from NPC.
  AVAILABLE
  /// Quest is active but requirements are not met yet.
  IN_PROGRESS
  /// Quest is active and can be completed at NPC.
  COMPLETED
} derive(Eq, Debug, ToJson, @json.FromJson)

///|
pub(all) struct QuestIconQueryResult {
  /// NPC template id.
  npc_id : Int
  /// Quest id selected for icon display.
  quest_id : Int
  /// Icon state to render.
  state : QuestIconState
}

///|
priv struct PlayerDeps {
  item_count_provider : (Int) -> Int
  char_stats_provider : () -> @char_stats.CharStats
  player_quest_log : PlayerQuestLog
}

///|
/// Resources for `MapQuests`.
struct MapQuestsResource {
  /// Icon shown when a quest is available from an NPC.
  available_quest_icon : @resource.NxAnimation
  /// Icon shown when a quest is in progress with an NPC.
  inprogress_quest_icon : @resource.NxAnimation
  /// Icon shown when a quest can be completed with an NPC.
  completed_quest_icon : @resource.NxAnimation
}

///|
/// Creates quest icon resources from caller-provided animations.
pub fn MapQuestsResource::new(
  available_quest_icon : @resource.NxAnimation,
  inprogress_quest_icon : @resource.NxAnimation,
  completed_quest_icon : @resource.NxAnimation,
) -> MapQuestsResource {
  { available_quest_icon, inprogress_quest_icon, completed_quest_icon }
}

///|
/// Loads the graphical resources for quest icons.
pub fn MapQuestsResource::load() -> MapQuestsResource {
  {
    available_quest_icon: @json.from_json(
      @resource.json_navigate("assets/UI/UIWindow2.img/QuestIcon.json", ["0"]),
    ) catch {
      _ => abort("invalid available quest icon")
    },
    inprogress_quest_icon: @json.from_json(
      @resource.json_navigate("assets/UI/UIWindow2.img/QuestIcon.json", ["1"]),
    ) catch {
      _ => abort("invalid in-progress quest icon")
    },
    completed_quest_icon: @json.from_json(
      @resource.json_navigate("assets/UI/UIWindow2.img/QuestIcon.json", ["2"]),
    ) catch {
      _ => abort("invalid completed quest icon")
    },
  }
}

///|
fn MapQuests::new(
  resource : MapQuestsResource,
  quests_resource : QuestResource,
  npc_quests_map : Map[Int, Array[Int]],
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
  get_player_deps : (@player.Player) -> PlayerDeps,
) -> MapQuests {
  {
    resource,
    quests_resource,
    npc_quests_map,
    player_deps: None,
    open_npc_talk_ui,
    get_player_deps,
    npc_to_icon_entity: {},
    quest_to_npc_id: {},
    npc_runtime: {},
  }
}

///|
/// Sets the current player context used by quest requirement checks.
pub fn MapQuests::set_player(self : MapQuests, player : @player.Player) -> Unit {
  self.player_deps = Some((self.get_player_deps)(player))
}

///|
/// Adds or refreshes the quest icon state for one NPC.
///
/// `npc_entity` is the parent entity used to spawn a child icon entity.
pub fn MapQuests::add_npc(
  self : MapQuests,
  npc_id : Int,
  npc_entity : @entity.Entity,
  npc_object : @physics.MovingObject,
) -> Unit {
  self.remove_npc(npc_id)
  guard self.query_npc_quest(npc_id) is Some(quest) else { return }
  let runtime = spawn_icon_runtime(quest, npc_entity, npc_object)
  self.npc_to_icon_entity.set(npc_id, runtime.icon_entity)
  self.quest_to_npc_id.set(quest.quest_id, npc_id)
  self.npc_runtime.set(npc_id, runtime)
}

///|
pub fn MapQuests::query_npc_icon(
  self : MapQuests,
  npc_id : Int,
) -> QuestIconQueryResult? {
  self
  .query_npc_quest(npc_id)
  .map(fn(quest) {
    { npc_id, quest_id: quest.quest_id, state: quest.icon_state }
  })
}

///|
pub fn MapQuests::build_quest_talk_args(
  self : MapQuests,
  quest_id : Int,
  npc_id : Int,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> @npc.TalkArgs? {
  guard self.query_npc_quest(npc_id) is Some(quest) else { return None }
  guard quest.quest_id == quest_id else { return None }
  guard self.quests_resource.quest_say_map.get(quest_id) is Some(phase_says) else {
    return None
  }
  build_talk_args_for_quest(quest, phase_says, open_npc_talk_ui)
}

///|
fn MapQuests::query_npc_quest(self : MapQuests, npc_id : Int) -> NpcQuest? {
  guard self.player_deps
    is Some({ player_quest_log, item_count_provider, char_stats_provider }) else {
    @log.error("player not set yet", data={ "npc_id": npc_id })
    return None
  }

  for quest_id, quest in player_quest_log.in_progress {
    guard quest.checks.get(quest.phase) is Some(check) else { continue }
    if check.npc != Some(npc_id) {
      continue
    }
    match
      check_quest_requirements(
        check,
        item_count_provider,
        char_stats_provider,
        player_quest_log,
        quest_id,
        quest.phase,
      ) {
      Ok(_) =>
        return Some(
          NpcQuest::new(
            quest_id,
            Some((quest.phase, true)),
            npc_id,
            QuestIconState::COMPLETED,
            self.resource.completed_quest_icon,
          ),
        )
      Err(err) => {
        @log.debug("quest completion check failed", data={
          "quest_id": quest_id,
          "error": err,
        })
        return Some(
          NpcQuest::new(
            quest_id,
            Some((quest.phase, false)),
            npc_id,
            QuestIconState::IN_PROGRESS,
            self.resource.inprogress_quest_icon,
          ),
        )
      }
    }
  }

  let quest_ids = list_quests_by_npc(self.npc_quests_map, npc_id)
  if filter_acceptable_quests(
      quest_ids.iter(),
      self.quests_resource,
      item_count_provider,
      char_stats_provider,
      player_quest_log,
    ).next()
    is Some((quest_id, _)) {
    return Some(
      NpcQuest::new(
        quest_id,
        None,
        npc_id,
        QuestIconState::AVAILABLE,
        self.resource.available_quest_icon,
      ),
    )
  }
  None
}

///|
/// Refreshes one quest icon by quest id.
pub fn MapQuests::update_quest(self : MapQuests, quest_id : Int) -> Unit {
  guard self.quest_to_npc_id.get(quest_id) is Some(npc_id) else { return }
  guard self.npc_runtime.get(npc_id) is Some(runtime) else {
    self.quest_to_npc_id.remove(quest_id)
    return
  }
  self.add_npc(npc_id, runtime.npc_entity, runtime.npc_object)
}

///|
/// Removes quest icon state for one NPC.
pub fn MapQuests::remove_npc(self : MapQuests, npc_id : Int) -> Unit {
  if self.npc_to_icon_entity.get(npc_id) is Some(entity) {
    destroy_icon_entity(entity)
    self.npc_to_icon_entity.remove(npc_id)
  }
  if self.npc_runtime.get(npc_id) is Some(runtime) {
    self.quest_to_npc_id.remove(runtime.quest.quest_id)
    self.npc_runtime.remove(npc_id)
  }
}

///|
/// Clears all quest icon state for current map.
pub fn MapQuests::clear(self : MapQuests) -> Unit {
  for _, icon_entity in self.npc_to_icon_entity {
    destroy_icon_entity(icon_entity)
  }
  self.npc_to_icon_entity.clear()
  self.quest_to_npc_id.clear()
  self.npc_runtime.clear()
}

///|
/// Handles cursor hit-test and click interaction on quest icons.
pub fn MapQuests::send_cursor(
  self : MapQuests,
  pressed : Bool,
  position : @struct.Point[Int],
  viewpos : @struct.Point[Int],
) -> @ui.CursorState? {
  for _, runtime in self.npc_runtime {
    if runtime.inrange(position, viewpos) {
      if pressed {
        guard self.quests_resource.quest_say_map.get(runtime.quest.quest_id)
          is Some(phase_says) else {
          return Some(@ui.CursorState::IDLE)
        }
        talk_about_quest(runtime.quest, phase_says, self.open_npc_talk_ui)
        return Some(@ui.CursorState::IDLE)
      }
      return Some(@ui.CursorState::CAN_CLICK)
    }
  }
  None
}

///|
priv struct NpcQuestRuntime {
  npc_entity : @entity.Entity
  npc_object : @physics.MovingObject
  icon_entity : @entity.Entity
  quest : NpcQuest
}

///|
fn NpcQuestRuntime::inrange(
  self : NpcQuestRuntime,
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int],
) -> Bool {
  self.quest.inrange(self.npc_object, cursorpos, viewpos)
}

///|
/// Represents one quest interaction entry for an NPC.
pub(all) struct NpcQuest {
  npc_id : Int
  icon_state : QuestIconState
  icon : @resource.NxAnimation
  icon_offset : @struct.Point[Int]
  icon_size : @struct.Point[Int]
  quest_id : Int
  in_progress_quest : (Int, Bool)?
}

///|
fn NpcQuest::new(
  quest_id : Int,
  in_progress_quest : (Int, Bool)?,
  npc_id : Int,
  icon_state : QuestIconState,
  icon : @resource.NxAnimation,
) -> NpcQuest {
  {
    quest_id,
    in_progress_quest,
    npc_id,
    icon_state,
    icon,
    icon_offset: @struct.Point::new(0, -96),
    icon_size: nx_animation_dimensions(icon),
  }
}

///|
fn NpcQuest::inrange(
  self : NpcQuest,
  npc_object : @physics.MovingObject,
  cursorpos : @struct.Point[Int],
  viewpos : @struct.Point[Int],
) -> Bool {
  let absp = npc_object.get_position() + self.icon_offset + viewpos
  let dim = self.icon_size
  @struct.Rectangle::from4(
    absp.x - dim.x / 2,
    absp.x + dim.x / 2,
    absp.y - dim.y,
    absp.y,
  ).contains(cursorpos)
}

///|
fn spawn_icon_runtime(
  quest : NpcQuest,
  npc_entity : @entity.Entity,
  npc_object : @physics.MovingObject,
) -> NpcQuestRuntime {
  let icon_entity = npc_entity.spawn_child()
  @transform2d.set_xy(
    icon_entity,
    @selene_math.Vec2(
      quest.icon_offset.x.to_double(),
      quest.icon_offset.y.to_double(),
    ),
  )
  let icon_animation = @ms_animation.from_nx_animation(quest.icon, loop_=true)
  @sprite.sprites().set(
    icon_entity,
    @ms_animation.sprite_from_animation(
      icon_animation,
      @graphics.OBJECT_TILE_LAYER_ZINDEX + QUEST_ICON_ZINDEX_OFFSET,
    ),
  )
  { npc_entity, npc_object, icon_entity, quest }
}
