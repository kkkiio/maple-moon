///|
struct Module {
  quests_resource : QuestsResource
  player_quest_log : PlayerQuestLog
  quest_log_listeners : Array[(PlayerQuestLog) -> Bool]
}

///|
pub fn Module::load() -> @utils.Future[Result[Module, Error]] {
  let fut = quest_resource_loader.load_res(["nx"])
  fut.map_exn(fn(node) {
    let quests_resource : QuestsResource = @json.from_json!(node.value())
    Module::new(quests_resource)
  })
}

///|
pub fn Module::new(quests_resource : QuestsResource) -> Module {
  {
    quests_resource,
    player_quest_log: PlayerQuestLog::default(),
    quest_log_listeners: [],
  }
}

///| PlayerQuestLog stores information on the quest log of an individual character
priv struct PlayerQuestLog {
  started : Map[Int, StartedQuest]
  completed : Map[Int, CompletedQuest]
} derive(Show, Default)

///|
priv struct StartedQuest {
  quest_info : QuestInfo
  checks : Array[QuestCheck]
  progress_data : String
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
  self.player_quest_log.started.clear()
  self.player_quest_log.completed.clear()
  for it in started {
    self.player_quest_log.started[it.0] = it.1
  }
  for it in completed {
    self.player_quest_log.completed[it.0] = it.1
  }
  self.quest_log_listeners.retain(fn(listener) {
    listener(self.player_quest_log)
  })
}

// what does negative quest id mean?
// 29005: "", 27010: "9", 29014: "", 27019: "3", -31066: ""

///|
struct QuestsResource {
  quest_info_map : Map[String, QuestInfo]
  quest_checks_map : Map[String, QuestChecks]
} derive (
  FromJson(
    fields(
      quest_info_map(rename="QuestInfo.img"),
      quest_checks_map(rename="Check.img"),
    ),
  ),
)

///|
priv struct QuestInfo {
  name : String
  parent : String?
  area : Int
  order : Int?
  auto_complete : Bool
  auto_start : Bool
  one_shot : Bool
  descriptions : Array[String]
} derive(Show)

///|
impl @json.FromJson for QuestInfo with from_json(json, path) {
  match json {
    Object(
      {
        "name": String(name),
        "parent"? : parent,
        "area": Number(area),
        "autoComplete"? : auto_complete,
        "autoStart"? : auto_start,
        "oneShot"? : one_shot,
        "order"? : order,
        ..
      } as obj
    ) => {
      let description_map : Map[Int, String] = {}
      for key, value in obj {
        let i = try {
          @strconv.parse_int!(key)
        } catch {
          _ => continue
        }
        if i < 0 || i > 10 { // assume there are at most 10 phases
          continue
        }
        description_map[i] = match value {
          String(desc) => desc
          Number(i) => i.to_string() // FIXME: what does number mean?
          _ => raise @json.JsonDecodeError((path.add_key(key), "invalid desc"))
        }
      }
      let max_phase : Int = description_map.keys().maximum().or(0)
      let descriptions = Array::makei(max_phase + 1, fn(i) {
        description_map.get_or_default(i, "")
      })
      {
        name,
        parent: match parent {
          Some(String(parent)) => Some(parent)
          Some(Number(1)) => Some("1") // TODO: what does the number 1 mean?
          None => None
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("parent"), "invalid parent"),
            )
        },
        area: area.to_int(),
        auto_complete: auto_complete is Some(1),
        auto_start: auto_start is Some(1),
        one_shot: one_shot is Some(1),
        order: match order {
          Some(Number(order)) => Some(order.to_int())
          None => None
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("order"), "invalid order"),
            )
        },
        descriptions,
      }
    }
    _ => raise @json.JsonDecodeError((path, "missing fields"))
  }
}

///|
test "parse quest 10015" {
  let q10015 =
    #| {
    #|     "1": "Today's Mission!! \\r\\n<Hunt in the mini dungeon and obtain #b1 Special Agent Badge#k!>\\r\\nToday's mission is obtaining a #bSpecial Agent Badge#k.  According to rumors, the Special Agent Badge can be found in the mini dungeon...\\nI should go see Agent O whom Gaga introduced me to.  If I haven't been introduced to #bAgent O#k yet, I should first go see #bAgent Gaga#k.",
    #|     "2": "Today's mission has been completed.",
    #|     "area": 50,
    #|     "autoComplete": 1,
    #|     "name": "Obtain the Special Agent Badge!",
    #|     "order": 1,
    #|     "parent": "Today's Mission! "
    #|   }
  let json = @json.parse!(q10015)
  let quest_info : QuestInfo = @json.from_json!(json)
  inspect!(
    quest_info,
    content=
      #|{name: "Obtain the Special Agent Badge!", parent: Some("Today's Mission! "), area: 50, order: Some(1), auto_complete: true, auto_start: false, one_shot: false, descriptions: ["", "Today's Mission!! \\r\\n<Hunt in the mini dungeon and obtain #b1 Special Agent Badge#k!>\\r\\nToday's mission is obtaining a #bSpecial Agent Badge#k.  According to rumors, the Special Agent Badge can be found in the mini dungeon...\\nI should go see Agent O whom Gaga introduced me to.  If I haven't been introduced to #bAgent O#k yet, I should first go see #bAgent Gaga#k.", "Today's mission has been completed."]}
    ,
  )
}

///|
test "parse quest 10200" {
  let q10200 =
    #|{
    #|  "0": "A new, potentially powerful individual is creating a lot of buzz in the world of Maple. Let's click on the light bulb that's flashing on top of the individual's head.",
    #|  "1": "Let's try to make a deal with #b#p2084001##k.",
    #|  "2": "I engaged in a transaction with #b#p2084001##k.",
    #|  "area": 50,
    #|  "autoComplete": 1,
    #|  "autoStart": 1,
    #|  "name": "Richie Gold is Here",
    #|  "oneShot": 1
    #|}
  let json = @json.parse!(q10200)
  let quest_info : QuestInfo = @json.from_json!(json)
  inspect!(
    quest_info,
    content=
      #|{name: "Richie Gold is Here", parent: None, area: 50, order: None, auto_complete: true, auto_start: true, one_shot: true, descriptions: ["A new, potentially powerful individual is creating a lot of buzz in the world of Maple. Let's click on the light bulb that's flashing on top of the individual's head.", "Let's try to make a deal with #b#p2084001##k.", "I engaged in a transaction with #b#p2084001##k."]}
    ,
  )
}

///|
test "parse number desc" {
  let q2003 =
    #|{
    #|  "0": 2,
    #|  "1": "Around \"The Victoria\" in Lith Harbor, I met this heavily-bearded crewmember called Teo. He said he has the #bWeird Medicine#k but he wasn't willing to give it up for free. Instead he said he'll trade with me for a #bsparkling rock#k. I mean, he does look like he knows Maya pretty well, but he still wants to make a deal with me, knowing how sick she is ...?? That's strange... anyway, to get that #bsparkling rock#k, I need to head over to Perion and talk to the #rSophia#k, the daughter of the owner of the department store there.",
    #|  "2": "I finally met Sophia, who's working at the department store in Perion. To make the sparkling rock, she said she needs #bArcon's blood#k.",
    #|  "area": 30,
    #|  "name": "Finding Sophia",
    #|  "order": 2,
    #|  "parent": "Maya and the Weird Medicine"
    #|}
  let json = @json.parse!(q2003)
  let quest_info : QuestInfo = @json.from_json!(json)
  inspect!(
    quest_info,
    content=
      #|{name: "Finding Sophia", parent: Some("Maya and the Weird Medicine"), area: 30, order: Some(2), auto_complete: false, auto_start: false, one_shot: false, descriptions: ["2", "Around \"The Victoria\" in Lith Harbor, I met this heavily-bearded crewmember called Teo. He said he has the #bWeird Medicine#k but he wasn't willing to give it up for free. Instead he said he'll trade with me for a #bsparkling rock#k. I mean, he does look like he knows Maya pretty well, but he still wants to make a deal with me, knowing how sick she is ...?? That's strange... anyway, to get that #bsparkling rock#k, I need to head over to Perion and talk to the #rSophia#k, the daughter of the owner of the department store there.", "I finally met Sophia, who's working at the department store in Perion. To make the sparkling rock, she said she needs #bArcon's blood#k."]}
    ,
  )
}

///|
test "parse number index not desc" {
  let q8833 =
    #|{
    #|  "0": "Can't believe its New Year's already! Looks like the Maple Administrator has something for me!",
    #|  "1": "Can't believe its New Year's already! Looks like the Maple Administrator has something for me!",
    #|  "2": "The Maple Administrator opened my present for me! Sweet!",
    #|  "4963": {
    #|    "0": "Mom and Dad need some help at home. I'd better go visit and see how I can help them.",
    #|    "1": "I visited Mom and Dad and they looked pretty happy to see me. They need a #bMouse#k for their new computer, and heard that Mr. Spot would have one. He's in Kerning City, so I'd better get a move on. ",
    #|    "2": "I returned to Mom and Dad with the #bMouse#k, and they gave me #bAllowance#k. Now I can return to Mr. Spot and get a #bNexon Prepaid!#k",
    #|    "area": 30,
    #|    "name": "Spot On : An Interesting Chore",
    #|    "order": 1,
    #|    "parent": "Spot On"
    #|  },
    #|  "area": 30,
    #|  "name": "New Year's Wishes 1",
    #|  "order": 1,
    #|  "parent": "New Year : New Year's Wishes"
    #|}
  let json = @json.parse!(q8833)
  let quest_info : QuestInfo = @json.from_json!(json)
  inspect!(quest_info, content=
    #|{name: "New Year's Wishes 1", parent: Some("New Year : New Year's Wishes"), area: 30, order: Some(1), auto_complete: false, auto_start: false, one_shot: false, descriptions: ["Can't believe its New Year's already! Looks like the Maple Administrator has something for me!", "Can't believe its New Year's already! Looks like the Maple Administrator has something for me!", "The Maple Administrator opened my present for me! Sweet!"]}
  )
}

///|
let quest_resource_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "Quest",
  loader=@resource.AsyncResourceLoader::new_async_resource_loader(
    @resource.DirResourceLoader::new("https://maple-res.kkkiiox.work/Quest"),
  ),
)

///|
typealias QuestChecks = @resource.MapBasedArray[QuestCheck]

///|
priv struct QuestCheck {
  npc : Int?
  info_number : Int?
  level_min : Int?
  info_ex : Array[InfoEx]
} derive(Show)

///|
priv struct InfoEx {
  value : String
} derive(Show, @json.FromJson)

///|
impl @json.FromJson for QuestCheck with from_json(json, path) {
  match json {
    Null => { npc: None, info_number: None, level_min: None, info_ex: [] }
    {
      "npc"? : npc,
      "infoNumber"? : info_number,
      "lvmin"? : level_min,
      "infoex"? : infoex,
      ..
    } => {
      let info_ex = if infoex is Some(infoex) {
        let arr : @resource.MapBasedArray[InfoEx] = @json.from_json!(
          infoex,
          path=path.add_key("infoex"),
        )
        arr._
      } else {
        []
      }
      {
        npc: match npc {
          Some(Number(npc)) => Some(npc.to_int())
          None => None
          _ => raise @json.JsonDecodeError((path.add_key("npc"), "invalid npc"))
        },
        info_number: match info_number {
          Some(Number(info_number)) => Some(info_number.to_int())
          Some(String(info_number)) =>
            try {
              Some(@strconv.parse_int!(info_number))
            } catch {
              _ =>
                raise @json.JsonDecodeError(
                  (path.add_key("infoNumber"), "invalid infoNumber"),
                )
            }
          None => None
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("infoNumber"), "invalid infoNumber"),
            )
        },
        info_ex,
        level_min: match level_min {
          Some(Number(level_min)) => Some(level_min.to_int())
          None => None
          _ =>
            raise @json.JsonDecodeError(
              (path.add_key("lvmin"), "invalid lvmin"),
            )
        },
      }
    }
    _ => raise @json.JsonDecodeError((path, "missing fields"))
  }
}

///|
test "parse quest check 10015" {
  let check_10015 =
    #|{
    #|  "0": {
    #|    "dayByDay": 1,
    #|    "end": "2009082600",
    #|    "infoNumber": 10024,
    #|    "infoex": { "0": { "value": "ing" } },
    #|    "lvmin": 10,
    #|    "npc": 9000036,
    #|    "start": "2009060100"
    #|  },
    #|  "1": {
    #|    "infoNumber": 10024,
    #|    "infoex": { "0": { "value": "clear" } },
    #|    "npc": 9000036
    #|  }
    #|}
  let json = @json.parse!(check_10015)
  let quest_check : QuestChecks = @json.from_json!(json)
  inspect!(
    quest_check,
    content=
      #|MapBasedArray([{npc: Some(9000036), info_number: Some(10024), level_min: Some(10), info_ex: [{value: "ing"}]}, {npc: Some(9000036), info_number: Some(10024), level_min: None, info_ex: [{value: "clear"}]}])
    ,
  )
}

///|
test "parse quest check 10054" {
  let check_10054 =
    #| {
    #|    "0": {
    #|      "end": "2008103000",
    #|      "infoNumber": 10057,
    #|      "infoex": {
    #|        "0": { "value": "000" },
    #|        "1": { "value": "100" },
    #|        "2": { "value": "001" },
    #|        "3": { "value": "101" }
    #|      },
    #|      "interval": 0,
    #|      "item": { "0": { "id": 4001204 } },
    #|      "lvmin": 50,
    #|      "npc": 9010000,
    #|      "quest": { "0": { "id": 10052, "state": 1 } },
    #|      "start": "2008101300"
    #|    },
    #|    "1": { "item": { "0": { "count": 1, "id": 2012000 } }, "npc": 1061013 }
    #|  }
  let json = @json.parse!(check_10054)
  let quest_check : QuestChecks = @json.from_json!(json)
  inspect!(
    quest_check,
    content=
      #|MapBasedArray([{npc: Some(9010000), info_number: Some(10057), level_min: Some(50), info_ex: [{value: "000"}, {value: "100"}, {value: "001"}, {value: "101"}]}, {npc: Some(1061013), info_number: None, level_min: None, info_ex: []}])
    ,
  )
}

///|
test "parse quest check 1008" {
  let check_1008 =
    #| {
    #|   "0": { "job": { "0": 0 }, "npc": 10000 },
    #|   "1": {
    #|     "item": {
    #|       "0": { "count": 1, "id": 4031162 },
    #|       "1": { "count": 1, "id": 4031161 }
    #|     }
    #|   }
    #| }
  let json = @json.parse!(check_1008)
  let quest_check : QuestChecks = @json.from_json!(json)
  inspect!(
    quest_check,
    content="MapBasedArray([{npc: Some(10000), info_number: None, level_min: None, info_ex: []}, {npc: None, info_number: None, level_min: None, info_ex: []}])",
  )
}
