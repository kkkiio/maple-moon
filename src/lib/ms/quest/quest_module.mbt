///|
struct Module {
  quests_resource : QuestResource
  name_loader : @markup_text.RefRender
  quest_log_listeners : Array[(PlayerQuestLog) -> Bool]
  map_quests : MapQuests
  network : @net.Network
  player_quest_log : Ref[PlayerQuestLog]
}

///|
pub fn Module::load(
  network : @net.Network,
  inventory : @inventory.Inventory,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit
) -> @utils.Future[Result[Module, Error]] {
  let fut = quest_resource_loader.load_res(["nx"])
  let fut2 = MapQuestsResource::load()
  @utils.Future::combine(fut, fut2).map_exn(fn(it) {
    let (node, map_quests_resource) = it
    let quests_resource : QuestResource = @json.from_json!(node.value())
    let name_loader = @markup_text.RefRender::load()
    Module::new(
      quests_resource,
      map_quests_resource.unwrap_or_error!(),
      network,
      inventory,
      open_npc_talk_ui,
      name_loader,
    )
  })
}

///|
pub fn Module::new(
  quests_resource : QuestResource,
  map_quests_resource : MapQuestsResource,
  network : @net.Network,
  inventory : @inventory.Inventory,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
  name_loader : @markup_text.RefRender
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
  {
    quests_resource,
    name_loader,
    player_quest_log,
    quest_log_listeners: [],
    map_quests: MapQuests::new( // TODO: update npc quests map when quest is completed
      map_quests_resource,
      quests_resource,
      npc_quests_map,
      network,
      open_npc_talk_ui,
      fn(player) {
        {
          player_quest_log: player_quest_log.val,
          item_count_provider: fn(item_id) { inventory.get_item_count(item_id) },
          char_stats_provider: fn() { player.stats },
        }
      },
    ),
    network,
  }
}

///|
pub fn Module::make_show_status_info_handler_map(
  self : Module
) -> Map[Int, @game_mod.SubRouteHandler] {
  {
    1: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction! {
      let quest_id = recv.read_short!()
      let status = recv.read_byte!()
      match status {
        0 => {
          let action : &@game_mod.SubRouteAction = ShowForfeitQuestAction::new(
            quest_id, self,
          )
          action
        }
        2 => {
          let action : &@game_mod.SubRouteAction = ShowCompleteQuestAction::new(
            { quest_id, completion_time: recv.read_long!() },
            self,
          )
          action
        }
        _ => {
          let action : &@game_mod.SubRouteAction = ShowUpdateQuestAction::new(
            quest_id,
            recv.read_string!(),
            self,
          )
          action
        }
      }
    },
    3: fn(recv : @net.InPacket) -> &@game_mod.SubRouteAction! {
      let white = recv.read_bool!()
      let gain = recv.read_int!()
      let in_chat = recv.read_bool!()
      let bonus_event_exp = recv.read_int!()
      let third_monster_kill_event = recv.read_byte!()
      let _ = recv.read_byte!() // rip_byte
      let wedding_bonus = recv.read_int!()
      let quest_bonus_rate = if in_chat {
        Some(recv.read_byte!())
      } else {
        None
      }
      let party_bonus_multiplier = recv.read_byte!()
      let party_bonus = recv.read_int!()
      let equip_bonus = recv.read_int!()
      let internet_cafe_bonus = recv.read_int!()
      let rainbow_week_bonus = recv.read_int!()
      let action : &@game_mod.SubRouteAction = ShowExpGainAction::new({
        white,
        gain,
        in_chat,
        bonus_event_exp,
        third_monster_kill_event,
        wedding_bonus,
        quest_bonus_rate,
        party_bonus_multiplier,
        party_bonus,
        equip_bonus,
        internet_cafe_bonus,
        rainbow_week_bonus,
      })
      action
    },
  }
}

///|
pub fn Module::get_map_quests(self : Module) -> MapQuests {
  self.map_quests
}

///| PlayerQuestLog stores information on the quest log of an individual character
priv struct PlayerQuestLog {
  in_progress : Map[Int, InProgressQuest]
  info_number_quest_map : Map[Int, Int] // info_number => quest_id
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
  phase : Int
) -> String {
  self.checks
  .get(phase)
  .bind(fn(it) { it.info_number })
  .bind(fn(it) { self.info_number_progress_map.get(it) })
  .or(self.progress_data)
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
  quest_id : Int
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
struct PlayerQuestLogInfo {
  started : Array[(Int, String)]
  completed : Array[(Int, Int64)]
} derive(Show)

///|
pub fn parse_player_quest_info(recv : @net.InPacket) -> PlayerQuestLogInfo! {
  let started_size = recv.read_short!()
  let started = []
  let completed = []
  for i in 0..<started_size {
    let quest_id = recv.read_short!()
    let progress_data = recv.read_string!()
    started.push((quest_id, progress_data))
  }
  let completed_size = recv.read_short!()
  for i in 0..<completed_size {
    let quest_id = recv.read_short!()
    let completion_time = recv.read_long!()
    completed.push((quest_id, completion_time))
  }
  { started, completed }
}

///|
pub fn Module::handle_player_quest_info(
  self : Module,
  player_quests : PlayerQuestLogInfo
) -> Unit {
  let in_progress : Array[(Int, InProgressQuest)] = []
  let completed : Array[(Int, CompletedQuest)] = []
  quest_loop~: for it in player_quests.started {
    let (id, progress_data) = it
    let quest_info = self.quests_resource.quest_info_map.get(id)
    if quest_info is None {
      // maybe a infoNumber
      if in_progress.last() is Some((_, last_in_progress_quest)) {
        for i, check in last_in_progress_quest.checks {
          if check.info_number is Some(info_number) && info_number == id { // is a infoNumber
            last_in_progress_quest.phase = i
            last_in_progress_quest.info_number_progress_map[id] = progress_data
            continue quest_loop~
          }
        }
      }
    }
    let quest_info = if quest_info is Some(quest_info) {
      quest_info
    } else {
      @log.warn({ "id": id }, "quest info not found")
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
    let checks = self.quests_resource.quest_checks_map.get(id)
    in_progress.push(
      (
        id,
        {
          quest_id: id,
          quest_info,
          checks: checks.or([]),
          acts: self.quests_resource.quest_acts_map.get(id).or([]),
          progress_data,
          phase: 1, // phase 0 is start requirements
          info_number_progress_map: {},
        },
      ),
    )
  }
  for it in player_quests.completed {
    let (quest_id, completion_time) = it
    let quest_info = self.quests_resource.quest_info_map.get(quest_id)
    let quest_info = if quest_info is Some(quest_info) {
      quest_info
    } else {
      @log.warn({ "quest_id": quest_id }, "quest info not found")
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
    completed.push((quest_id, { quest_id, quest_info, completion_time }))
  }
  self.player_quest_log.val = {
    in_progress: Map::from_array(in_progress),
    info_number_quest_map: in_progress
    .iter()
    .flat_map(fn(it) {
      let (quest_id, quest) = it
      quest.checks
      .iter()
      .filter_map(fn(check) {
        check.info_number.map(fn(info_number) { (info_number, quest_id) })
      })
    })
    |> Map::from_iter,
    completed: Map::from_array(completed),
  }
  self.quest_log_listeners.retain(fn(listener) {
    listener(self.player_quest_log.val)
  })
}

// what does negative quest id mean?
// 29005: "", 27010: "9", 29014: "", 27019: "3", -31066: ""

///|
priv struct ShowForfeitQuestAction {
  quest_id : Int
  mod : Module
}

///|
fn ShowForfeitQuestAction::new(
  quest_id : Int,
  mod : Module
) -> ShowForfeitQuestAction {
  { quest_id, mod }
}

///|
impl Show for ShowForfeitQuestAction with output(self, logger) {
  logger.write_string("{quest_id:\{self.quest_id}}")
}

///|
impl @game_mod.SubRouteAction for ShowForfeitQuestAction with handle(self) -> Unit {
  self.mod.player_quest_log.val.in_progress.remove(self.quest_id)
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log.val)
  })
}

///|
priv struct ShowCompleteQuestMessage {
  quest_id : Int
  completion_time : Int64
} derive(Show)

///|
priv struct ShowCompleteQuestAction {
  message : ShowCompleteQuestMessage
  mod : Module
}

///|
fn ShowCompleteQuestAction::new(
  message : ShowCompleteQuestMessage,
  mod : Module
) -> ShowCompleteQuestAction {
  { message, mod }
}

///|
impl Show for ShowCompleteQuestAction with output(self, logger) {
  self.message.output(logger)
}

///|
impl @game_mod.SubRouteAction for ShowCompleteQuestAction with handle(self) -> Unit {
  let quest_id = self.message.quest_id
  let completion_time = self.message.completion_time
  let quest_info = self.mod.quests_resource.quest_info_map.get(quest_id)
  let quest_info = if quest_info is Some(quest_info) {
    quest_info
  } else {
    @log.warn({ "quest_id": quest_id }, "quest info not found")
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
  self.mod.player_quest_log.val.in_progress.remove(quest_id)
  self.mod.player_quest_log.val.completed[quest_id] = {
    quest_id,
    quest_info,
    completion_time,
  }
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log.val)
  })
}

///|
priv struct ShowUpdateQuestAction {
  quest_id : Int
  progress_data : String
  mod : Module
}

///|
fn ShowUpdateQuestAction::new(
  quest_id : Int,
  progress_data : String,
  mod : Module
) -> ShowUpdateQuestAction {
  { quest_id, progress_data, mod }
}

///|
impl Show for ShowUpdateQuestAction with output(self, logger) {
  logger.write_string(
    "{quest_id:\{self.quest_id}, progress_data:\{self.progress_data}}",
  )
}

///|
impl @game_mod.SubRouteAction for ShowUpdateQuestAction with handle(self) -> Unit {
  guard self.mod.player_quest_log.val.in_progress.get(self.quest_id)
    is Some(quest) else {
    return
  }
  quest.progress_data = self.progress_data
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log.val)
  })
}

///| list all quests that can be started by npc
fn list_quests_by_npc(
  npc_quests_map : Map[Int, Array[Int]],
  npc_id : Int
) -> Array[Int] {
  npc_quests_map.get(npc_id).map_or([], fn(quest_ids) { quest_ids })
}

///| list all acceptable quests by npc
/// 
/// This function returns an iterator of all quests that can be started by the player
fn filter_acceptable_quests(
  quest_ids : Iter[Int],
  quests_resource : QuestResource,
  item_count_provider : (Int) -> Int,
  char_stats_provider : () -> @char_stats.CharStats,
  quest_log : PlayerQuestLog
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

///| check if a quest can be started or completed
fn check_quest_requirements(
  check : QuestPhaseChecks,
  item_count_provider : (Int) -> Int,
  char_stats_provider : () -> @char_stats.CharStats,
  quest_log : PlayerQuestLog,
  quest_id : Int,
  phase : Int
) -> Result[Unit, String] {
  if check.unknown_checks.length() > 0 {
    @log.warn(
      { "quest_id": quest_id, "unknown_checks": check.unknown_checks },
      "unknown checks",
    )
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

///|
impl @game_mod.SubRouteAction for ShowExpGainAction with handle(_) -> Unit {
  // TODO: Add UI handling to display EXP gain popup/notification
  // TODO: Add any quest-related EXP gain processing if needed
}
