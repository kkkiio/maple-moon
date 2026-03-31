///|
using @quest {
  type QuestResource,
  type NxQuestInfo,
  type NxQuestPhaseChecks,
  type StartedQuest,
}

///|
struct Module {
  quests_resource : QuestResource
  quest_checks_raw : Json
  map_quests : MapQuests
}

///|
let active_module : Ref[Module?] = Ref::new(None)

///|
pub(all) struct DemoQuestSelection {
  /// Selected quest id.
  quest_id : Int
  /// NPC template id bound to the selected quest.
  npc_id : Int
  /// Whether phase0 check includes a level requirement.
  has_level_check : Bool
} derive(Show)

///|
let quest_icon_query_revision_ref : Ref[Int] = Ref::new(0)

///|
let selected_demo_quest : Ref[DemoQuestSelection?] = Ref::new(None)

///|
/// Returns monotonic revision used by quest-icon query caches.
pub fn quest_icon_query_revision() -> Int {
  quest_icon_query_revision_ref.val
}

///|
/// Queries the quest-icon state for one NPC from the active quest module.
pub fn query_npc_icon(npc_id : Int) -> QuestIconQueryResult? {
  active_module.val.bind(fn(m) { m.query_npc_icon(npc_id) })
}

///|
/// Builds NPC talk arguments for one quest interaction from the active module.
pub fn build_quest_talk_args(quest_id : Int, npc_id : Int) -> @npc.TalkArgs? {
  active_module.val.bind(fn(m) {
    m.map_quests.build_quest_talk_args(
      quest_id, npc_id, @npc.request_quest_talk,
    )
  })
}

///|
/// Returns selected low-restriction demo quest in current runtime.
pub fn get_demo_quest_selection() -> DemoQuestSelection? {
  selected_demo_quest.val
}

///|
/// Selects one low-restriction quest from current map NPC ids for icon validation.
pub fn select_demo_quest_by_npcs(npc_ids : Array[Int]) -> DemoQuestSelection? {
  let selection = active_module.val.bind(fn(m) {
    m.select_demo_quest_by_npcs(npc_ids)
  })
  selected_demo_quest.val = selection
  selection
}

///|
/// Binds current player to quest runtime checks.
pub fn bind_player(player : @player.Player) -> Unit {
  match active_module.val {
    Some(m) => {
      m.map_quests.set_player(player)
      bump_quest_icon_query_revision()
    }
    None => ()
  }
}

///|
/// Refreshes one quest state in the active module.
pub fn refresh_quest(quest_id : Int) -> Unit {
  match active_module.val {
    Some(m) => {
      m.map_quests.update_quest(quest_id)
      bump_quest_icon_query_revision()
    }
    None => ()
  }
}

///|
fn bump_quest_icon_query_revision() -> Unit {
  quest_icon_query_revision_ref.val = quest_icon_query_revision_ref.val + 1
}

///|
/// 初始化 quest_icon 模块
pub fn setup(
  quests_resource : QuestResource,
  quest_checks_raw : Json,
  map_quests_resource : MapQuestsResource,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Unit {
  // 构建 npc_quests_map: npc_id -> quest_ids[]
  let npc_quests_map : Map[Int, Array[Int]] = {}
  for quest_id, phase_checks in quests_resource.quest_checks_map {
    // 从 phase 0 获取 npc
    match phase_checks.get(0) {
      Some(check) =>
        match check.npc {
          Some(npc_id) => {
            if !npc_quests_map.contains(npc_id) {
              npc_quests_map[npc_id] = []
            }
            npc_quests_map[npc_id].push(quest_id)
          }
          None => ()
        }
      None => ()
    }
  }
  let get_player_deps = fn(player : @player.Player) {
    {
      item_count_provider: fn(item_id) {
        @inventory.inventory.val.get_item_count(item_id)
      },
      char_stats_provider: fn() { player.get_stats() },
      player_quest_log: @quest_log.current_player_quest_log(),
    }
  }
  let map_quests = MapQuests::new(
    map_quests_resource, quests_resource, npc_quests_map, open_npc_talk_ui, get_player_deps,
  )
  let mod = { quests_resource, quest_checks_raw, map_quests }
  active_module.val = Some(mod)
  bump_quest_icon_query_revision()
}

///|
fn Module::select_demo_quest_by_npcs(
  self : Module,
  npc_ids : Array[Int],
) -> DemoQuestSelection? {
  let seen : Map[Int, Unit] = {}
  let mut candidate_count = 0
  for npc_id in npc_ids {
    if seen.contains(npc_id) {
      continue
    }
    seen.set(npc_id, ())
    let quest_ids = list_quests_by_npc(self.map_quests.npc_quests_map, npc_id)
    for quest_id in quest_ids {
      let (low_restriction, has_level_check) = is_low_restriction_phase0(
        self.quest_checks_raw,
        self.quests_resource.quest_checks_map,
        quest_id,
        npc_id,
      )
      if !low_restriction {
        continue
      }
      candidate_count = candidate_count + 1
      if self.map_quests.query_npc_icon(npc_id)
        is Some({ quest_id: shown_quest_id, .. }) &&
        shown_quest_id == quest_id {
        let selection = { quest_id, npc_id, has_level_check }
        @log.info("selected low restriction quest for quest icon validation", data={
          "quest_id": quest_id,
          "npc_id": npc_id,
          "has_level_check": has_level_check,
        })
        return Some(selection)
      }
      self.log_low_restriction_rejection(quest_id, npc_id)
    }
  }
  @log.warn("no low restriction quest icon is currently visible", data={
    "npc_count": npc_ids.length(),
    "candidate_count": candidate_count,
  })
  None
}

///|
fn Module::log_low_restriction_rejection(
  self : Module,
  quest_id : Int,
  npc_id : Int,
) -> Unit {
  guard self.quests_resource.quest_checks_map.get(quest_id) is Some(all_checks) else {
    @log.warn("low restriction quest rejected: missing check data", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
    })
    return
  }
  guard all_checks.get(0) is Some(check0) else {
    @log.warn("low restriction quest rejected: missing phase0", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
    })
    return
  }
  let status = @quest_log.current_player_quest_log().get_quest(quest_id)
  if !is_quest_status_can_start(status, check0.repeatable) {
    @log.warn("low restriction quest rejected: status cannot start", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
      "status": status,
    })
    return
  }
  guard self.map_quests.player_deps
    is Some({ player_quest_log, item_count_provider, char_stats_provider }) else {
    @log.warn("low restriction quest rejected: player deps not initialized", data={
      "quest_id": quest_id,
      "npc_id": npc_id,
    })
    return
  }
  match
    check_quest_requirements(
      check0, item_count_provider, char_stats_provider, player_quest_log, quest_id,
      0,
    ) {
    Ok(_) =>
      @log.warn("low restriction quest rejected: icon conflict or priority", data={
        "quest_id": quest_id,
        "npc_id": npc_id,
      })
    Err(err) =>
      @log.debug("low restriction quest rejected: start requirement not met", data={
        "quest_id": quest_id,
        "npc_id": npc_id,
        "reason": err,
      })
  }
}

///|
fn is_low_restriction_phase0(
  quest_checks_raw : Json,
  quest_checks_map : Map[Int, Array[NxQuestPhaseChecks]],
  quest_id : Int,
  npc_id : Int,
) -> (Bool, Bool) {
  match is_low_restriction_phase0_raw(quest_checks_raw, quest_id, npc_id) {
    Some(result) => return result
    None => ()
  }
  is_low_restriction_phase0_from_checks(quest_checks_map, quest_id, npc_id)
}

///|
fn is_low_restriction_phase0_raw(
  quest_checks_raw : Json,
  quest_id : Int,
  npc_id : Int,
) -> (Bool, Bool)? {
  guard quest_checks_raw is Object(it) &&
    it.get(quest_id.to_string()) is Some(Object(it2)) &&
    it2.get("0") is Some(Object(phase0)) else {
    return None
  }
  guard phase0.get("npc") is Some(Number(raw_npc, ..)) else {
    return Some((false, false))
  }
  if raw_npc.to_int() != npc_id {
    return Some((false, false))
  }
  let has_level_check = phase0.contains("lvmin")
  for key, _ in phase0 {
    if key == "item" ||
      key == "mob" ||
      key == "quest" ||
      key == "job" ||
      key == "interval" ||
      key == "infoex" {
      return Some((false, false))
    }
  }
  Some((true, has_level_check))
}

///|
fn is_low_restriction_phase0_from_checks(
  quest_checks_map : Map[Int, Array[NxQuestPhaseChecks]],
  quest_id : Int,
  npc_id : Int,
) -> (Bool, Bool) {
  guard quest_checks_map.get(quest_id) is Some(all_checks) else {
    return (false, false)
  }
  guard all_checks.get(0) is Some(phase0) else { return (false, false) }
  guard phase0.npc is Some(phase_npc) else { return (false, false) }
  if phase_npc != npc_id {
    return (false, false)
  }
  // Fallback path used when raw Check.img JSON is unavailable in tests.
  // Keep it conservative and only accept simple NPC / level quests.
  if phase0.repeatable ||
    phase0.info_number is Some(_) ||
    phase0.unknown_checks.length() > 0 ||
    phase0.monster_hunts.length() > 0 ||
    phase0.checks.length() > 2 {
    return (false, false)
  }
  let has_level_check = phase0.checks.length() == 2
  (true, has_level_check)
}

///|
/// list all quests that can be started by npc
fn list_quests_by_npc(
  npc_quests_map : Map[Int, Array[Int]],
  npc_id : Int,
) -> Array[Int] {
  npc_quests_map.get(npc_id).map_or([], fn(quest_ids) { quest_ids })
}

///|
/// list all acceptable quests by npc
///
/// This function returns an iterator of all quests that can be started by the player
fn filter_acceptable_quests(
  quest_ids : Iter[Int],
  quests_resource : QuestResource,
  item_count_provider : (Int) -> Int,
  char_stats_provider : () -> @char_stats.CharStats,
  quest_log : PlayerQuestLog,
) -> Iter[(Int, NxQuestInfo)] {
  quest_ids.filter_map(fn(quest_id) {
    guard quests_resource.quest_checks_map.get(quest_id)
      is Some(all_phase_checks) else {
      return None
    }
    let phase = 0
    if all_phase_checks
      .get(phase)
      .map_or(true, fn(checks) {
        let status = quest_log.get_quest(quest_id)
        if !is_quest_status_can_start(status, checks.repeatable) {
          return false
        }
        if check_quest_requirements(
            checks, item_count_provider, char_stats_provider, quest_log, quest_id,
            phase,
          )
          is Err(_) {
          return false
        }
        true
      }) {
      quests_resource.quest_info_map
      .get(quest_id)
      .map(fn(quest_info) { (quest_id, quest_info) })
    } else {
      None
    }
  })
}

///|
/// check if a quest can be started or completed
fn check_quest_requirements(
  check : NxQuestPhaseChecks,
  item_count_provider : (Int) -> Int,
  char_stats_provider : () -> @char_stats.CharStats,
  quest_log : PlayerQuestLog,
  quest_id : Int,
  phase : Int,
) -> Result[Unit, String] {
  if check.unknown_checks.length() > 0 {
    return Err("Unknown checks: \{check.unknown_checks}")
  }
  for check in check.checks {
    if check.check({
        log: quest_log,
        item_count_provider,
        char_stats_provider,
        quest_id,
        phase,
      })
      is Err(e) {
      return Err(e)
    }
  }
  Ok(())
}

///|
fn is_quest_status_can_start(status : StartedQuest?, repeatable : Bool) -> Bool {
  status is None || (status is Some(Completed(_)) && repeatable)
}

///|
pub fn Module::query_npc_icon(
  self : Module,
  npc_id : Int,
) -> QuestIconQueryResult? {
  self.map_quests.query_npc_icon(npc_id)
}
