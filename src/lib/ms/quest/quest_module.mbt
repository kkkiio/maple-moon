///|
struct Module {
  quests_resource : QuestsResource
  mut player_quest_log : PlayerQuestLog
  quest_log_listeners : Array[(PlayerQuestLog) -> Bool]
  network : @net.Network
}

///|
pub fn Module::load(
  network : @net.Network
) -> @utils.Future[Result[Module, Error]] {
  let fut = quest_resource_loader.load_res(["nx"])
  fut.map_exn(fn(node) {
    let quests_resource : QuestsResource = @json.from_json!(node.value())
    Module::new(quests_resource, network)
  })
}

///|
pub fn Module::new(
  quests_resource : QuestsResource,
  network : @net.Network
) -> Module {
  {
    quests_resource,
    player_quest_log: PlayerQuestLog::default(),
    quest_log_listeners: [],
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
            quest_id,
            recv.read_long!(),
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
  }
}

///| PlayerQuestLog stores information on the quest log of an individual character
priv struct PlayerQuestLog {
  started : Map[Int, StartedQuest]
  info_number_quest_map : Map[Int, Int] // info_number => quest_id
  completed : Map[Int, CompletedQuest]
} derive(Show, Default)

///|
priv struct StartedQuest {
  quest_info : QuestInfo
  checks : Array[QuestCheck]
  mut progress_data : String
  mut phase : Int
  mut current_phase_info : (Int, String)? // info_number, progress
} derive(Show)

///|
priv struct CompletedQuest {
  quest_info : QuestInfo
  completion_time : Int64
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
  let started : Array[(Int, StartedQuest)] = []
  let completed : Array[(Int, CompletedQuest)] = []
  quest_loop~: for it in player_quests.started {
    let (id, progress_data) = it
    let quest_info = self.quests_resource.quest_info_map.get(id.to_string())
    if quest_info is None {
      // maybe a infoNumber
      if started.last() is Some((_, last_started_quest)) {
        for i, check in last_started_quest.checks {
          if check.info_number is Some(info_number) && info_number == id { // is a infoNumber
            last_started_quest.phase = i
            last_started_quest.current_phase_info = Some((id, progress_data))
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
    let checks = self.quests_resource.quest_checks_map.get(id.to_string())
    started.push(
      (
        id,
        {
          quest_info,
          checks: checks.map_or([], fn(c) { c._ }),
          progress_data,
          phase: 0,
          current_phase_info: None,
        },
      ),
    )
  }
  for it in player_quests.completed {
    let (quest_id, completion_time) = it
    let quest_info = self.quests_resource.quest_info_map.get(
      quest_id.to_string(),
    )
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
    completed.push((quest_id, { quest_info, completion_time }))
  }
  self.player_quest_log = {
    started: Map::from_array(started),
    info_number_quest_map: started
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
    listener(self.player_quest_log)
  })
}

// what does negative quest id mean?
// 29005: "", 27010: "9", 29014: "", 27019: "3", -31066: ""

///|
priv enum QuestActionMessage {
  // Restore a lost item for a quest.
  RestoreLostItem(quest_id~ : Int, item_id~ : Int)
  // Start a quest when talking to an NPC.
  StartQuest(quest_id~ : Int, npc_id~ : Int)
  // Complete a quest when talking to an NPC, optionally with a selection.
  CompleteQuest(quest_id~ : Int, npc_id~ : Int, selection~ : Int?)
  // Forfeit an active quest.
  ForfeitQuest(quest_id~ : Int)
  // Start a quest via a script (e.g., item-triggered or event-triggered).
  ScriptedStartQuest(quest_id~ : Int, npc_id~ : Int)
  // Complete a quest via a script.
  ScriptedEndQuest(quest_id~ : Int, npc_id~ : Int)
} derive(Show)

///|
impl @net.OutMessage for QuestActionMessage with pack(self) -> @net.OutPacket {
  let packet = @net.OutPacket::new(@net.ClientOpcode::QUEST_ACTION)
  match self {
    QuestActionMessage::RestoreLostItem(quest_id~, item_id~) => {
      packet.write_byte(0)
      packet.write_short(quest_id)
      packet.write_int(0) // unknonw int
      packet.write_int(item_id)
    }
    QuestActionMessage::StartQuest(quest_id~, npc_id~) => {
      packet.write_byte(1)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
    QuestActionMessage::CompleteQuest(quest_id~, npc_id~, selection~) => {
      packet.write_byte(2)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
      if selection is Some(selection) {
        packet.write_short(selection)
      }
    }
    QuestActionMessage::ForfeitQuest(quest_id~) => {
      packet.write_byte(3)
      packet.write_short(quest_id)
    }
    QuestActionMessage::ScriptedStartQuest(quest_id~, npc_id~) => {
      packet.write_byte(4)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
    QuestActionMessage::ScriptedEndQuest(quest_id~, npc_id~) => {
      packet.write_byte(5)
      packet.write_short(quest_id)
      packet.write_int(npc_id)
    }
  }
  packet
}

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
  self.mod.player_quest_log.started.remove(self.quest_id)
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log)
  })
}

///|
priv struct ShowCompleteQuestAction {
  quest_id : Int
  completion_time : Int64
  mod : Module
}

///|
fn ShowCompleteQuestAction::new(
  quest_id : Int,
  completion_time : Int64,
  mod : Module
) -> ShowCompleteQuestAction {
  { quest_id, completion_time, mod }
}

///|
impl Show for ShowCompleteQuestAction with output(self, logger) {
  logger.write_string(
    "{quest_id:\{self.quest_id}, completion_time:\{self.completion_time}}",
  )
}

///|
impl @game_mod.SubRouteAction for ShowCompleteQuestAction with handle(self) -> Unit {
  let quest_info = self.mod.quests_resource.quest_info_map.get(
    self.quest_id.to_string(),
  )
  let quest_info = if quest_info is Some(quest_info) {
    quest_info
  } else {
    @log.warn({ "quest_id": self.quest_id }, "quest info not found")
    {
      name: "Unknown Quest \{self.quest_id}",
      parent: None,
      area: 0,
      order: None,
      auto_complete: false,
      auto_start: false,
      one_shot: false,
      descriptions: [],
    }
  }
  self.mod.player_quest_log.started.remove(self.quest_id)
  self.mod.player_quest_log.completed[self.quest_id] = {
    quest_info,
    completion_time: self.completion_time,
  }
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log)
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
  guard self.mod.player_quest_log.started.get(self.quest_id) is Some(quest) else {
    return
  }
  quest.progress_data = self.progress_data
  self.mod.quest_log_listeners.retain(fn(listener) {
    listener(self.mod.player_quest_log)
  })
}
