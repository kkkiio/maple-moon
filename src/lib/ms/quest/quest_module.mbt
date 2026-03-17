///|
struct Module {
  quests_resource : QuestResource
  quest_checks_raw : Json
  ref_render : @markup_text.RefRender
  quest_log_listeners : Array[(PlayerQuestLog) -> Bool]
  map_quests : MapQuests
  inventory : @inventory.Inventory
  player_quest_log : Ref[PlayerQuestLog]
}

///|
let active_module : Ref[Module?] = Ref::new(None)

///|
let quest_icon_query_revision_ref : Ref[Int] = Ref::new(0)

///|
let inventory_changed_reader_ref : Ref[
  @event.EventReader[@inventory.InventoryChangedEvent]?,
] = Ref::new(None)

///|
let char_stats_changed_reader_ref : Ref[
  @event.EventReader[@char_stats.CharStatsChangedEvent]?,
] = Ref::new(None)

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
let selected_demo_quest : Ref[DemoQuestSelection?] = Ref::new(None)

///|
/// Registers the active quest module instance for global query entrypoints.
pub fn set_active_module(mod : Module) -> Unit {
  active_module.val = Some(mod)
  bump_quest_icon_query_revision()
}

///|
/// Clears the active quest module binding.
pub fn clear_active_module() -> Unit {
  active_module.val = None
  selected_demo_quest.val = None
  bump_quest_icon_query_revision()
}

///|
/// Queries the quest-icon state for one NPC from the active quest module.
pub fn query_npc_icon(npc_id : Int) -> QuestIconQueryResult? {
  consume_external_state_events()
  active_module.val.bind(fn(m) { m.query_npc_icon(npc_id) })
}

///|
/// Builds NPC talk arguments for one quest interaction from the active module.
pub fn build_quest_talk_args(quest_id : Int, npc_id : Int) -> @npc.TalkArgs? {
  consume_external_state_events()
  active_module.val.bind(fn(m) {
    m.build_quest_talk_args(quest_id, npc_id, @npc.request_quest_talk)
  })
}

///|
/// Returns monotonic revision used by quest-icon query caches.
pub fn quest_icon_query_revision() -> Int {
  consume_external_state_events()
  quest_icon_query_revision_ref.val
}

///|
/// Refreshes one quest state in the active module.
pub fn refresh_quest(quest_id : Int) -> Unit {
  consume_external_state_events()
  match active_module.val {
    Some(m) => {
      m.map_quests.update_quest(quest_id)
      bump_quest_icon_query_revision()
    }
    None => ()
  }
}

///|
/// Binds current player to quest runtime checks.
pub fn bind_player(player : @player.Player) -> Unit {
  consume_external_state_events()
  match active_module.val {
    Some(m) => {
      m.map_quests.set_player(player)
      bump_quest_icon_query_revision()
    }
    None => ()
  }
}

///|
/// Applies `SET_FIELD` quest log snapshot to active quest module.
pub fn handle_player_quest_info(player_quests : PlayerQuestLogInfo) -> Unit {
  consume_external_state_events()
  match active_module.val {
    Some(m) => {
      m.handle_player_quest_info(player_quests)
      bump_quest_icon_query_revision()
    }
    None => ()
  }
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
/// Registers quest packet handlers used by the runtime.
pub fn setup_game_server_handlers() -> Unit {
  @game_server.add_server_message_handler(
    "update_quest_info",
    @server_proto.Opcode::UPDATE_QUEST_INFO.int_value(),
    fn(json) raise {
      let msg : UpdateQuestInfoMessage = @json.from_json(json)
      handle_update_quest_info_message(msg)
    },
  )
}

///|
fn handle_update_quest_info_message(msg : UpdateQuestInfoMessage) -> Unit {
  match msg {
    QuestUpdate(quest_id~, ..) => refresh_quest(quest_id)
    QuestFinish(quest_id~, next_quest=0, ..) => refresh_quest(quest_id)
    _ => ()
  }
}

///|
fn bump_quest_icon_query_revision() -> Unit {
  quest_icon_query_revision_ref.val = quest_icon_query_revision_ref.val + 1
}

///|
fn get_inventory_changed_reader() -> @event.EventReader[
  @inventory.InventoryChangedEvent,
] {
  match inventory_changed_reader_ref.val {
    Some(reader) => reader
    None => {
      let reader : @event.EventReader[@inventory.InventoryChangedEvent] = @event.EventReader::new()
      inventory_changed_reader_ref.val = Some(reader)
      reader
    }
  }
}

///|
fn get_char_stats_changed_reader() -> @event.EventReader[
  @char_stats.CharStatsChangedEvent,
] {
  match char_stats_changed_reader_ref.val {
    Some(reader) => reader
    None => {
      let reader : @event.EventReader[@char_stats.CharStatsChangedEvent] = @event.EventReader::new()
      char_stats_changed_reader_ref.val = Some(reader)
      reader
    }
  }
}

///|
fn consume_external_state_events() -> Unit {
  let inventory_events = @inventory.inventory_changed_event_bus.read(
    get_inventory_changed_reader(),
  )
  let char_stat_events = @char_stats.char_stats_changed_event_bus.read(
    get_char_stats_changed_reader(),
  )
  if not(inventory_events.is_empty()) || not(char_stat_events.is_empty()) {
    bump_quest_icon_query_revision()
  }
}

///|
pub async fn Module::load(
  inventory : @inventory.Inventory,
  ref_render : @markup_text.RefRender,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Module {
  let quest_resource_loader = @resource.get_quest_loader()
  let raw = quest_resource_loader.load_resource(["nx"])
  let quests_resource : QuestResource = @json.from_json(raw) catch {
    e => {
      @log.error("failed to decode quest resource", data={
        "error": e.to_string(),
      })
      panic()
    }
  }
  let map_quests_resource = MapQuestsResource::load()
  let quest_checks_raw = match raw {
    { "Check.img": check_raw, .. } => check_raw
    _ => Json::null()
  }
  Module::new_internal(
    quests_resource, quest_checks_raw, map_quests_resource, inventory, ref_render,
    open_npc_talk_ui,
  )
}

///|
pub fn Module::new(
  quests_resource : QuestResource,
  map_quests_resource : MapQuestsResource,
  inventory : @inventory.Inventory,
  ref_render : @markup_text.RefRender,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Module {
  Module::new_internal(
    quests_resource,
    Json::null(),
    map_quests_resource,
    inventory,
    ref_render,
    open_npc_talk_ui,
  )
}

///|
/// Creates a quest module with explicit raw `Check.img` JSON for strict filtering.
pub fn Module::new_with_raw_checks(
  quests_resource : QuestResource,
  quest_checks_raw : Json,
  map_quests_resource : MapQuestsResource,
  inventory : @inventory.Inventory,
  ref_render : @markup_text.RefRender,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Module {
  Module::new_internal(
    quests_resource, quest_checks_raw, map_quests_resource, inventory, ref_render,
    open_npc_talk_ui,
  )
}

///|
fn Module::new_internal(
  quests_resource : QuestResource,
  quest_checks_raw : Json,
  map_quests_resource : MapQuestsResource,
  inventory : @inventory.Inventory,
  ref_render : @markup_text.RefRender,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Module {
  let npc_quests_map = quests_resource.quest_checks_map
    .iter()
    .filter_map(fn(it) {
      let (quest_id, all_phase_checks) = it
      guard all_phase_checks.get(0) is Some({ npc: Some(npc_id), .. }) else {
        return None
      }
      Some((npc_id, quest_id))
    })
    .fold(init=Map::new(), fn(acc, it) {
      let (npc_id, quest_id) = it
      acc.get_or_init(npc_id, fn() { [] }).push(quest_id)
      acc
    })
  let player_quest_log = Ref::new(PlayerQuestLog::default())
  let mod = {
    quests_resource,
    quest_checks_raw,
    ref_render,
    player_quest_log,
    quest_log_listeners: [],
    map_quests: MapQuests::new( // TODO: update npc quests map when quest is completed
      map_quests_resource,
      quests_resource,
      npc_quests_map,
      open_npc_talk_ui,
      fn(player) {
        {
          player_quest_log: player_quest_log.val,
          item_count_provider: fn(item_id) { inventory.get_item_count(item_id) },
          char_stats_provider: fn() { player.stats },
        }
      },
    ),
    inventory,
  }
  set_active_module(mod)
  mod
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
      if not(low_restriction) {
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
  let status = self.player_quest_log.val.get_quest(quest_id)
  if not(is_quest_status_can_start(status, check0.repeatable)) {
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
  quest_checks_map : Map[Int, Array[QuestPhaseChecks]],
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
  guard quest_checks_raw
    .as_object()
    .bind(fn(it) { it.get(quest_id.to_string()) })
    .bind(fn(it) { it.as_object() })
    .bind(fn(it) { it.get("0") })
    .bind(fn(it) { it.as_object() })
    is Some(phase0) else {
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
  quest_checks_map : Map[Int, Array[QuestPhaseChecks]],
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

// ///|
// pub fn Module::make_handlers(
//   self : Module,
// ) -> Map[@server_proto.Opcode, (@net.InPacket) -> Unit] {
//   [
//     @net.make_handler(
//       @server_proto.Opcode::UPDATE_QUEST_INFO,
//       parse_update_quest_info,
//       fn(msg) { self.handle_update_quest_info(msg) },
//     ),
//   ]
//   |> Map::from_array
// }

// ///|
// pub fn Module::make_show_status_info_handlers(
//   self : Module,
// ) -> Map[Int, @game_mod.SubRouteHandler] {
//   {
//     1: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction raise {
//       let quest_id = recv.read_short()
//       let status = recv.read_byte()
//       match status {
//         0 => {
//           let action : &@game_mod.SubRouteAction = ShowForfeitQuestAction::new(
//             quest_id, self,
//           )
//           action
//         }
//         2 => {
//           let action : &@game_mod.SubRouteAction = ShowCompleteQuestAction::new(
//             { quest_id, completion_time: recv.read_long() },
//             self,
//           )
//           action
//         }
//         _ => {
//           let action : &@game_mod.SubRouteAction = ShowUpdateQuestAction::new(
//             { quest_id, progress_data: recv.read_string() },
//             self,
//           )
//           action
//         }
//       }
//     },
//     3: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction raise {
//       let white = recv.read_bool()
//       let gain = recv.read_int()
//       let in_chat = recv.read_bool()
//       let bonus_event_exp = recv.read_int()
//       let third_monster_kill_event = recv.read_byte()
//       let _ = recv.read_byte() // rip_byte
//       let wedding_bonus = recv.read_int()
//       let quest_bonus_rate = if in_chat { Some(recv.read_byte()) } else { None }
//       let party_bonus_multiplier = recv.read_byte()
//       let party_bonus = recv.read_int()
//       let equip_bonus = recv.read_int()
//       let internet_cafe_bonus = recv.read_int()
//       let rainbow_week_bonus = recv.read_int()
//       let action : &@game_mod.SubRouteAction = ShowExpGainAction::new({
//         white,
//         gain,
//         in_chat,
//         bonus_event_exp,
//         third_monster_kill_event,
//         wedding_bonus,
//         quest_bonus_rate,
//         party_bonus_multiplier,
//         party_bonus,
//         equip_bonus,
//         internet_cafe_bonus,
//         rainbow_week_bonus,
//       })
//       action
//     },
//   }
// }

///|
pub fn Module::get_map_quests(self : Module) -> MapQuests {
  self.map_quests
}

///|
pub fn Module::query_npc_icon(
  self : Module,
  npc_id : Int,
) -> QuestIconQueryResult? {
  self.map_quests.query_npc_icon(npc_id)
}

///|
pub fn Module::build_quest_talk_args(
  self : Module,
  quest_id : Int,
  npc_id : Int,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> @npc.TalkArgs? {
  self.map_quests.build_quest_talk_args(quest_id, npc_id, open_npc_talk_ui)
}

///|
/// PlayerQuestLog stores information on the quest log of an individual character
priv struct PlayerQuestLog {
  in_progress : Map[Int, InProgressQuest]
  completed : Map[Int, CompletedQuest]
} derive(Show, Default)

///|
priv struct InProgressQuest {
  quest_id : Int
  quest_info : QuestInfo
  checks : Array[QuestPhaseChecks]
  acts : Array[QuestPhaseAct]
  mut progress_data : String
  mut phase : Int
  info_number_progress_map : Map[Int, String]
} derive(Show)

///|
fn InProgressQuest::get_phase_progress(
  self : InProgressQuest,
  phase : Int,
) -> String {
  self.checks
  .get(phase)
  .bind(fn(it) { it.info_number })
  .bind(fn(it) { self.info_number_progress_map.get(it) })
  .unwrap_or(self.progress_data)
}

///|
priv struct CompletedQuest {
  quest_id : Int
  quest_info : QuestInfo
  completion_time : Int64
} derive(Show)

///|
fn PlayerQuestLog::get_quest(
  self : PlayerQuestLog,
  quest_id : Int,
) -> StartedQuest? {
  if self.in_progress.get(quest_id) is Some(in_progress_quest) {
    Some(InProgress(in_progress_quest))
  } else if self.completed.get(quest_id) is Some(completed_quest) {
    Some(Completed(completed_quest))
  } else {
    None
  }
}

///|
priv enum StartedQuest {
  InProgress(InProgressQuest)
  Completed(CompletedQuest)
} derive(Show)

///|
using @server_proto {type PlayerQuestLogInfo, type UpdateQuestInfoMessage}

// ///|
// pub fn parse_player_quest_info(
//   recv : @net.InPacket,
// ) -> PlayerQuestLogInfo raise {
//   let started_size = recv.read_short()
//   let started = []
//   let completed = []
//   for i in 0..<started_size {
//     let quest_id = recv.read_short()
//     let progress_data = recv.read_string()
//     started.push((quest_id, progress_data))
//   }
//   let completed_size = recv.read_short()
//   for i in 0..<completed_size {
//     let quest_id = recv.read_short()
//     let completion_time = recv.read_long()
//     completed.push((quest_id, completion_time))
//   }
//   { started, completed }
// }

// ///|
// fn parse_update_quest_info(
//   recv : @net.InPacket,
// ) -> UpdateQuestInfoMessage raise {
//   let operation = recv.read_byte()
//   match operation {
//     6 => {
//       // Add quest time limit: short size, short quest_id, int time
//       let size = recv.read_short()
//       let quest_id = recv.read_short()
//       let time = recv.read_int()
//       AddQuestTimeLimit(size, quest_id, time)
//     }
//     7 => {
//       // Remove quest time limit: short position, short quest_id
//       let position = recv.read_short()
//       let quest_id = recv.read_short()
//       RemoveQuestTimeLimit(position, quest_id)
//     }
//     8 => {
//       // Quest update/finish: short quest_id, int npc, (short next_quest or int 0)
//       let quest_id = recv.read_short()
//       let npc = recv.read_int()
//       if recv.available() == 2 {
//         let next_quest = recv.read_short()
//         QuestFinish(quest_id, npc, next_quest)
//       } else {
//         recv.read_int() |> ignore // 0
//         QuestUpdate(quest_id, npc)
//       }
//     }
//     0x0A => {
//       // Quest error: short quest_id
//       let quest_id = recv.read_short()
//       QuestError(quest_id)
//     }
//     0x0F => {
//       // Quest expire: short quest_id  
//       let quest_id = recv.read_short()
//       QuestExpire(quest_id)
//     }
//     _ =>
//       // For other operation types (0x0B, 0x0D, 0x0E), just store the operation
//       match operation {
//         0x0B => QuestFailure(NoMeso)
//         0x0D => QuestFailure(WornByCharacter)
//         0x0E => QuestFailure(NotHavingItem)
//         _ => fail("Unknown quest failure operation: \{operation}")
//       }
//   }
// }

///|
pub fn Module::handle_player_quest_info(
  self : Module,
  player_quests : PlayerQuestLogInfo,
) -> Unit {
  self.player_quest_log.val = PlayerQuestLog::from_packet(
    self.quests_resource,
    player_quests,
  )
  bump_quest_icon_query_revision()
  self.quest_log_listeners.retain(fn(listener) {
    listener(self.player_quest_log.val)
  })
}

///|
fn PlayerQuestLog::from_packet(
  quests_resource : QuestResource,
  player_quests : PlayerQuestLogInfo,
) -> PlayerQuestLog {
  let quest_log = { in_progress: {}, completed: {} }
  let mut last_in_progress_quest : InProgressQuest? = None
  quest_loop~: for it in player_quests.started {
    let (id, progress_data) = it
    let quest_info = quests_resource.quest_info_map.get(id)
    if quest_info is None {
      // maybe a infoNumber
      if last_in_progress_quest is Some(last_in_progress_quest) {
        for i, check in last_in_progress_quest.checks {
          if check.info_number is Some(info_number) && info_number == id { // is a infoNumber
            last_in_progress_quest.phase = i
            last_in_progress_quest.info_number_progress_map[id] = progress_data
            continue quest_loop~
          }
        }
      }
    }
    let quest = quest_log.add_in_progress_quest(
      quests_resource, id, progress_data,
    )
    last_in_progress_quest = Some(quest)
  }
  for it in player_quests.completed {
    let (quest_id, completion_time) = it
    let quest_info = quests_resource.quest_info_map.get(quest_id)
    let quest_info = if quest_info is Some(quest_info) {
      quest_info
    } else {
      @log.warn("quest info not found", data={ "quest_id": quest_id })
      {
        name: "Unknown Quest \{quest_id}",
        parent: None,
        area: 0,
        order: None,
        auto_complete: false,
        auto_start: false,
        one_shot: false,
        descriptions: [],
      }
    }
    quest_log.completed[quest_id] = { quest_id, quest_info, completion_time }
  }
  quest_log
}

///|
fn PlayerQuestLog::add_in_progress_quest(
  self : PlayerQuestLog,
  quests_resource : QuestResource,
  quest_id : Int,
  progress_data : String,
) -> InProgressQuest {
  let id = quest_id
  let quest_info = quests_resource.quest_info_map.get(quest_id)
  let quest_info = if quest_info is Some(quest_info) {
    quest_info
  } else {
    @log.warn("quest info not found", data={ "id": id })
    {
      name: "Unknown Quest \{id}",
      parent: None,
      area: 0,
      order: None,
      auto_complete: false,
      auto_start: false,
      one_shot: false,
      descriptions: [],
    }
  }
  let checks = quests_resource.quest_checks_map.get(id)
  let quest = {
    quest_id: id,
    quest_info,
    checks: checks.unwrap_or([]),
    acts: quests_resource.quest_acts_map.get(id).unwrap_or([]),
    progress_data,
    phase: 1, // phase 0 is start requirements
    info_number_progress_map: {},
  }
  self.in_progress[id] = quest
  quest
}

// what does negative quest id mean?
// 29005: "", 27010: "9", 29014: "", 27019: "3", -31066: ""

///|
priv struct ShowForfeitQuestAction {
  quest_id : Int
  _mod : Module
}

///|
fn ShowForfeitQuestAction::new(
  quest_id : Int,
  mod : Module,
) -> ShowForfeitQuestAction {
  { quest_id, _mod: mod }
}

///|
impl Show for ShowForfeitQuestAction with output(self, logger) {
  logger.write_string("{quest_id:\{self.quest_id}}")
}

// ///|
// impl @game_mod.SubRouteAction for ShowForfeitQuestAction with handle(self) -> Unit {
//   self.mod.player_quest_log.val.in_progress.remove(self.quest_id)
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
// }

///|
priv struct ShowCompleteQuestMessage {
  quest_id : Int
  completion_time : Int64
} derive(Show)

///|
priv struct ShowCompleteQuestAction {
  message : ShowCompleteQuestMessage
  _mod : Module
}

///|
fn ShowCompleteQuestAction::new(
  message : ShowCompleteQuestMessage,
  mod : Module,
) -> ShowCompleteQuestAction {
  { message, _mod: mod }
}

///|
impl Show for ShowCompleteQuestAction with output(self, logger) {
  self.message.output(logger)
}

// ///|
// impl @game_mod.SubRouteAction for ShowCompleteQuestAction with handle(self) -> Unit {
//   let quest_id = self.message.quest_id
//   let completion_time = self.message.completion_time
//   let quest_info = self.mod.quests_resource.quest_info_map.get(quest_id)
//   let quest_info = if quest_info is Some(quest_info) {
//     quest_info
//   } else {
//     @log.warn("quest info not found", data={ "quest_id": quest_id })
//     {
//       name: "Unknown Quest \{quest_id}",
//       parent: None,
//       area: 0,
//       order: None,
//       auto_complete: false,
//       auto_start: false,
//       one_shot: false,
//       descriptions: [],
//     }
//   }
//   self.mod.player_quest_log.val.in_progress.remove(quest_id)
//   self.mod.player_quest_log.val.completed[quest_id] = {
//     quest_id,
//     quest_info,
//     completion_time,
//   }
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
//   self.mod.map_quests.update_quest(quest_id)
// }

///|
priv struct ShowUpdateQuestMessage {
  quest_id : Int
  progress_data : String
} derive(Show)

///|
priv struct ShowUpdateQuestAction {
  message : ShowUpdateQuestMessage
  mod : Module
}

///|
fn ShowUpdateQuestAction::new(
  message : ShowUpdateQuestMessage,
  mod : Module,
) -> ShowUpdateQuestAction {
  { message, mod }
}

///|
impl Show for ShowUpdateQuestAction with output(self, logger) {
  self.message.output(logger)
}

// ///|
// impl @game_mod.SubRouteAction for ShowUpdateQuestAction with handle(self) -> Unit {
//   let player_quest_log = self.mod.player_quest_log.val
//   let quest = if player_quest_log.in_progress.get(self.message.quest_id)
//     is Some(quest) {
//     quest
//   } else {
//     // accept quest
//     guard self.mod.quests_resource.quest_info_map.get(self.message.quest_id)
//       is Some(quest_info) else {
//       @log.warn("quest info not found", data={
//         "quest_id": self.message.quest_id,
//       })
//       return
//     }
//     let quest = {
//       quest_id: self.message.quest_id,
//       quest_info,
//       checks: [],
//       acts: [],
//       progress_data: "",
//       phase: 0,
//       info_number_progress_map: {},
//     }
//     player_quest_log.in_progress.set(self.message.quest_id, quest)
//     quest
//   }
//   quest.progress_data = self.message.progress_data
//   self.mod.quest_log_listeners.retain(fn(listener) {
//     listener(self.mod.player_quest_log.val)
//   })
//   self.mod.map_quests.update_quest(self.message.quest_id) // TODO: convert to listener
// }

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
) -> Iter[(Int, QuestInfo)] {
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
        if not(is_quest_status_can_start(status, checks.repeatable)) {
          return false
        }
        if check_quest_requirements(
            checks, item_count_provider, char_stats_provider, quest_log, quest_id,
            phase,
          )
          is Err(_) {
          // @log.debug(
          //   { "quest_id": quest_id, "reason": error },
          //   "cannot start quest",
          // )
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
  check : QuestPhaseChecks,
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
priv struct ShowExpGainMessage {
  white : Bool
  gain : Int
  in_chat : Bool
  bonus_event_exp : Int
  third_monster_kill_event : Int
  wedding_bonus : Int
  quest_bonus_rate : Int?
  party_bonus_multiplier : Int
  party_bonus : Int
  equip_bonus : Int
  internet_cafe_bonus : Int
  rainbow_week_bonus : Int
} derive(Show)

///|
priv struct ShowExpGainAction {
  message : ShowExpGainMessage
}

///|
fn ShowExpGainAction::new(message : ShowExpGainMessage) -> ShowExpGainAction {
  { message, }
}

///|
impl Show for ShowExpGainAction with output(self, logger) {
  logger.write_string("{message:\{self.message}}")
}

// ///|
// impl @game_mod.SubRouteAction for ShowExpGainAction with handle(_) -> Unit {
//   // TODO: Add UI handling to display EXP gain popup/notification
//   // TODO: Add any quest-related EXP gain processing if needed
// }

///|
fn Module::handle_update_quest_info(
  self : Module,
  msg : UpdateQuestInfoMessage,
) -> Unit {
  match msg {
    QuestUpdate(quest_id~, ..) => {
      self.map_quests.update_quest(quest_id)
      bump_quest_icon_query_revision()
    }
    QuestFinish(quest_id~, next_quest=0, ..) => {
      self.map_quests.update_quest(quest_id)
      bump_quest_icon_query_revision()
    }
    _ => ()
  }
}
