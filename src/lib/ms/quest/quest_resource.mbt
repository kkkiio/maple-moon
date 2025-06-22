///|
pub struct QuestResource {
  quest_info_map : Map[Int, QuestInfo]
  quest_checks_map : Map[Int, Array[QuestPhaseChecks]]
  quest_say_map : Map[Int, Array[QuestPhaseSays]]
  quest_acts_map : Map[Int, Array[QuestPhaseAct]]
}

///|
pub impl @json.FromJson for QuestResource with from_json(json, path) {
  let parsed : QuestNxResource = @json.from_json(json, path~)
  {
    quest_info_map: parsed.quest_info_map.inner(),
    quest_checks_map: parsed.quest_checks_map.inner()
    .iter()
    .map(fn(i) { (i.0, i.1.inner()) })
    |> Map::from_iter(),
    quest_say_map: parsed.quest_say_map.inner()
    .iter()
    .map(fn(i) { (i.0, i.1.inner()) })
    |> Map::from_iter(),
    quest_acts_map: parsed.quest_acts_map.inner()
    .iter()
    .map(fn(i) { (i.0, i.1.inner()) })
    |> Map::from_iter(),
  }
}

///|
priv struct QuestNxResource {
  quest_info_map : IntMap[QuestInfo]
  quest_checks_map : IntMap[@resource.MapBasedArray[QuestPhaseChecks]]
  quest_say_map : IntMap[@resource.MapBasedArray[QuestPhaseSays]]
  quest_acts_map : IntMap[@resource.MapBasedArray[QuestPhaseAct]]
} derive (
  FromJson(
    fields(
      quest_info_map(rename="QuestInfo.img"),
      quest_checks_map(rename="Check.img"),
      quest_say_map(rename="Say.img"),
      quest_acts_map(rename="Act.img"),
    ),
  ),
)

///|
let quest_resource_loader : @resource.AsyncLoader = @resource.AsyncLoader::new(
  "Quest",
  loader=@resource.AsyncResourceLoader::new_async_resource_loader(
    @resource.DirResourceLoader::new("https://maple-res.kkkiiox.work/Quest"),
  ),
)

///|
struct QuestInfo {
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
        let i = @strconv.parse_int(key) catch { _ => continue }
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
test "parse quest info" {
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
  let json = @json.parse(q10015)
  let quest_info : QuestInfo = @json.from_json(json)
  inspect(
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
  let json = @json.parse(q10200)
  let quest_info : QuestInfo = @json.from_json(json)
  inspect(
    quest_info,
    content=
      #|{name: "Richie Gold is Here", parent: None, area: 50, order: None, auto_complete: true, auto_start: true, one_shot: true, descriptions: ["A new, potentially powerful individual is creating a lot of buzz in the world of Maple. Let's click on the light bulb that's flashing on top of the individual's head.", "Let's try to make a deal with #b#p2084001##k.", "I engaged in a transaction with #b#p2084001##k."]}
    ,
  )
}

///|
test "parse quest info number desc" {
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
  let json = @json.parse(q2003)
  let quest_info : QuestInfo = @json.from_json(json)
  inspect(
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
  let json = @json.parse(q8833)
  let quest_info : QuestInfo = @json.from_json(json)
  inspect(
    quest_info,
    content=
      #|{name: "New Year's Wishes 1", parent: Some("New Year : New Year's Wishes"), area: 30, order: Some(1), auto_complete: false, auto_start: false, one_shot: false, descriptions: ["Can't believe its New Year's already! Looks like the Maple Administrator has something for me!", "Can't believe its New Year's already! Looks like the Maple Administrator has something for me!", "The Maple Administrator opened my present for me! Sweet!"]}
    ,
  )
}

///|
struct QuestPhaseChecks {
  npc : Int?
  info_number : Int?
  repeatable : Bool
  monster_hunts : Array[MonHuntCheck]
  checks : Array[&QuestCheck]
  unknown_checks : Array[String]
} derive(Show, Default)

///|
priv struct InfoEx {
  value : String
} derive(Show, @json.FromJson)

///|
typealias @resource.Nullable

///|
priv type NumbericInt Int derive(Show)

///|
impl @json.FromJson for NumbericInt with from_json(json, path) {
  match json {
    Number(n) => n.to_int()
    String(s) =>
      @strconv.parse_int(s) catch {
        _ => raise @json.JsonDecodeError((path, "expect stringified int"))
      }
    _ => raise @json.JsonDecodeError((path, "expect number or string"))
  }
}

///|
fn NumbericInt::value(self : NumbericInt) -> Int {
  self.inner()
}

///|
priv struct MonHuntCheck {
  id : Int
  count : Int
} derive(Show, @json.FromJson)

///|
impl @json.FromJson for QuestPhaseChecks with from_json(json, path) {
  let obj = match json {
    Null => return QuestPhaseChecks::default()
    Object(obj) => obj
    _ => raise @json.JsonDecodeError((path, "expect object or null"))
  }
  let mut npc : Int? = None
  let mut info_number : Int? = None
  let checks : Array[&QuestCheck] = []
  let unknown_checks : Array[String] = []
  let mut repeatable : Bool = false
  let mut monster_hunts : Array[MonHuntCheck] = []
  for key, value in obj {
    let path = path.add_key(key)
    match key {
      "npc" => {
        let npc_id : NumbericInt = @json.from_json(value, path~)
        checks.push({ npc: npc_id.inner() })
        npc = Some(npc_id.inner())
      }
      "infoNumber" => {
        let info_number_id : NumbericInt = @json.from_json(value, path~)
        info_number = Some(info_number_id.inner())
      }
      "lvmin" => {
        let level_min_id : NumbericInt = @json.from_json(value, path~)
        checks.push({ min_level: level_min_id.inner() })
      }
      "interval" => {
        let interval_minutes : NumbericInt = @json.from_json(value, path~)
        repeatable = true
        checks.push({ interval_minutes: interval_minutes.inner() })
      }
      "infoex" => {
        let info_ex_value : @resource.MapBasedArray[InfoEx] = @json.from_json(
          value,
          path~,
        )
        checks.push({ info_ex: info_ex_value.inner() })
      }
      "quest" => {
        let quest_status_map : @resource.MapBasedArray[QuestStatusCheck] = @json.from_json(
          value,
          path~,
        )
        checks.push({
          quest_status_map: quest_status_map.inner()
          .iter()
          .map(fn(i) { (i.id, i.state) })
          |> Map::from_iter(),
        })
      }
      "job" => {
        let jobs : @resource.MapBasedArray[@job.JobId] = @json.from_json(
          value,
          path~,
        )
        checks.push({ jobs: jobs.inner() })
      }
      "mob" => {
        let mob : @resource.MapBasedArray[MonHuntCheck] = @json.from_json(
          value,
          path~,
        )
        monster_hunts = mob.inner()
        checks.push({ monster_hunts, })
      }
      "item" => {
        let items : @resource.MapBasedArray[ItemCount] = @json.from_json(
          value,
          path~,
        )
        checks.push({ items: items.inner() })
      }
      _ => unknown_checks.push(key)
    }
  }
  { npc, info_number, repeatable, checks, unknown_checks, monster_hunts }
}

///|
priv struct QuestStatusCheck {
  id : Int
  state : QuestStatus
} derive(Show)

///|
impl @json.FromJson for QuestStatusCheck with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let id : Int = @json.from_json(obj.get("id").or(Json::null()), path~)
  let state = @json.from_json(obj.get("state").or(Json::number(0)), path~)
  { id, state }
}

///|
pub(all) enum QuestStatus {
  NotStarted = 0
  InProgress = 1
  Completed = 2
} derive(Show, Eq, Hash)

///|
fn QuestStatus::int_value(self : QuestStatus) = "%identity"

///|
fn QuestStatus::from_int(int_value : Int) -> QuestStatus? {
  let status = match int_value {
    0 => QuestStatus::NotStarted
    1 => QuestStatus::InProgress
    2 => QuestStatus::Completed
    _ => return None
  }
  Some(status)
}

///|
impl @json.FromJson for QuestStatus with from_json(json, path) {
  let int_value = @json.from_json(json, path~)
  if QuestStatus::from_int(int_value) is Some(status) {
    status
  } else {
    raise @json.JsonDecodeError((path, "Unknown quest status: \{int_value}"))
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
  let json = @json.parse(check_10015)
  let quest_check : @resource.MapBasedArray[QuestPhaseChecks] = @json.from_json(
    json,
  )
  inspect(
    quest_check,
    content=
      #|MapBasedArray([{npc: Some(9000036), info_number: Some(10024), repeatable: false, monster_hunts: [], checks: [{info_ex: [{value: "ing"}]}, {min_level: 10}, {npc: 9000036}], unknown_checks: ["dayByDay", "end", "start"]}, {npc: Some(9000036), info_number: Some(10024), repeatable: false, monster_hunts: [], checks: [{info_ex: [{value: "clear"}]}, {npc: 9000036}], unknown_checks: []}])
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
  let json = @json.parse(check_10054)
  let quest_check : @resource.MapBasedArray[QuestPhaseChecks] = @json.from_json(
    json,
  )
  inspect(
    quest_check.inner(),
    content=
      #|[{npc: Some(9010000), info_number: Some(10057), repeatable: true, monster_hunts: [], checks: [{info_ex: [{value: "000"}, {value: "100"}, {value: "001"}, {value: "101"}]}, {interval_minutes: 0}, {items: [{id: 4001204, count: 0}]}, {min_level: 50}, {npc: 9010000}, {quest_status_map: {10052: InProgress}}], unknown_checks: ["end", "start"]}, {npc: Some(1061013), info_number: None, repeatable: false, monster_hunts: [], checks: [{items: [{id: 2012000, count: 1}]}, {npc: 1061013}], unknown_checks: []}]
    ,
  )
}

///|
test "parse item check" {
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
  let json = @json.parse(check_1008)
  let quest_check : @resource.MapBasedArray[QuestPhaseChecks] = @json.from_json(
    json,
  )
  inspect(
    quest_check,
    content="MapBasedArray([{npc: Some(10000), info_number: None, repeatable: false, monster_hunts: [], checks: [{jobs: [Beginner]}, {npc: 10000}], unknown_checks: []}, {npc: None, info_number: None, repeatable: false, monster_hunts: [], checks: [{items: [{id: 4031162, count: 1}, {id: 4031161, count: 1}]}], unknown_checks: []}])",
  )
}

///|
test "parse quests status check" {
  let check_2005 =
    #| {
    #|   "0": {
    #|     "lvmin": 15,
    #|     "npc": 1022002,
    #|     "quest": { "0": { "id": 2004, "state": 2 } }
    #|   },
    #|   "1": { "item": { "0": { "count": 40, "id": 4000008 } }, "npc": 1022002 }
    #| }
  let json = @json.parse(check_2005)
  let quest_check : @resource.MapBasedArray[QuestPhaseChecks] = @json.from_json(
    json,
  )
  inspect(
    quest_check,
    content="MapBasedArray([{npc: Some(1022002), info_number: None, repeatable: false, monster_hunts: [], checks: [{min_level: 15}, {npc: 1022002}, {quest_status_map: {2004: Completed}}], unknown_checks: []}, {npc: Some(1022002), info_number: None, repeatable: false, monster_hunts: [], checks: [{items: [{id: 4000008, count: 40}]}, {npc: 1022002}], unknown_checks: []}])",
  )
}

///|
priv struct ItemCount {
  id : Int
  count : Int // 0 means should not hold the item
} derive(Show)

///|
impl @json.FromJson for ItemCount with from_json(json, path) {
  match json {
    { "id": Number(id), "count": Number(count), .. } =>
      { id: id.to_int(), count: count.to_int() }
    { "id": Number(id), .. } => { id: id.to_int(), count: 0 }
    _ => raise @json.JsonDecodeError((path, "expect object"))
  }
}

///|
struct QuestPhaseSays {
  says : Array[String]
  ask : Bool
  yes_reply : Array[String]
  no_reply : Array[String]
  stop : Hints?
  restore_lost : Lost?
} derive(Show, Default)

///|
priv struct Hints {
  base : Array[Hint]
  item : Array[String]
  npc : Array[String]
} derive(Show)

///|
priv struct Hint { // TODO: figure out the meaning of this
  says : Array[String]
  answer : Int
} derive(Show, Default)

///|
priv struct Lost {
  says : Array[String]
  yes_reply : Array[String]
} derive(Show)

///|
pub impl @json.FromJson for QuestPhaseSays with from_json(json, path) {
  let obj = match json {
    Null => return QuestPhaseSays::default() // TODO: figure out the meaning of this
    Object(obj) => obj
    _ => raise @json.JsonDecodeError((path, "expect object or null"))
  }
  let says : @resource.MapBasedArray[String] = @json.from_json(json, path~)
  let yes_reply : Nullable[@resource.MapBasedArray[String]] = @json.from_json(
    obj.get("yes").or(Json::null()),
    path=path.add_key("yes"),
  )
  let no_reply : Nullable[@resource.MapBasedArray[String]] = @json.from_json(
    obj.get("no").or(Json::null()),
    path=path.add_key("no"),
  )
  let stop_hint : Nullable[Hints] = @json.from_json(
    obj.get("stop").or(Json::null()),
    path=path.add_key("stop"),
  )
  let restore_lost : Nullable[Lost] = @json.from_json(
    obj.get("lost").or(Json::null()),
    path=path.add_key("lost"),
  )
  let ask = match obj.get("ask") {
    None => false
    Some(Null) => false
    Some(ask) => @json.from_json(ask, path=path.add_key("ask")) != 0
  }
  {
    says: says.inner(),
    ask,
    yes_reply: yes_reply.inner().map_or([], fn(reply) { reply.inner() }),
    no_reply: no_reply.inner().map_or([], fn(reply) { reply.inner() }),
    stop: stop_hint.inner(),
    restore_lost: restore_lost.inner(),
  }
}

///|
impl @json.FromJson for Hints with from_json(json, path) {
  let base : @resource.MapBasedArray[Hint] = @json.from_json(json, path~)
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let item : Nullable[@resource.MapBasedArray[String]] = @json.from_json(
    obj.get("item").or(Json::null()),
    path=path.add_key("item"),
  )
  let npc : Nullable[@resource.MapBasedArray[String]] = @json.from_json(
    obj.get("npc").or(Json::null()),
    path=path.add_key("npc"),
  )
  {
    base: base.inner(),
    item: item.inner().map_or([], fn(reply) { reply.inner() }),
    npc: npc.inner().map_or([], fn(reply) { reply.inner() }),
  }
}

///|
impl @json.FromJson for Hint with from_json(json, path) {
  let obj = match json {
    Null => return Hint::default() // TODO: figure out the meaning of this
    Object(obj) => obj
    _ => raise @json.JsonDecodeError((path, "expect object or null"))
  }
  let says : @resource.MapBasedArray[String] = @json.from_json(json, path~)
  let answer : Int = @json.from_json(
    obj.get("answer").or(Json::null()),
    path=path.add_key("answer"),
  )
  { says: says.inner(), answer }
}

///|
impl @json.FromJson for Lost with from_json(json, path) {
  let says : @resource.MapBasedArray[String] = @json.from_json(json, path~)
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let yes_reply : Nullable[@resource.MapBasedArray[String]] = @json.from_json(
    obj.get("yes").or(Json::null()),
    path=path.add_key("yes"),
  )
  {
    says: says.inner(),
    yes_reply: yes_reply.inner().map_or([], fn(reply) { reply.inner() }),
  }
}

///|
struct QuestPhaseAct {
  exp : Int?
  mesos : Int?
  items : Array[ActItem]
  unknown_acts : Array[String]
} derive(Show, Default)

///|
priv struct ActItem {
  id : Int
  count : Int?
  period : Int?
} derive(Show, Default)

///|
pub impl @json.FromJson for QuestPhaseAct with from_json(json, path) {
  let obj = match json {
    Null => return QuestPhaseAct::default()
    Object(obj) => obj
    _ => raise @json.JsonDecodeError((path, "expect object or null"))
  }
  let mut exp : Int? = None
  let mut mesos : Int? = None
  let items : Array[ActItem] = []
  let unknown_acts : Array[String] = []
  for key, value in obj {
    let path = path.add_key(key)
    match key {
      "exp" => {
        let exp_value : NumbericInt = @json.from_json(value, path~)
        exp = Some(exp_value.inner())
      }
      "money" => {
        let mesos_value : NumbericInt = @json.from_json(value, path~)
        mesos = Some(mesos_value.inner())
      }
      "item" => {
        let item_map : @resource.MapBasedArray[ActItem] = @json.from_json(
          value,
          path~,
        )
        items.append(item_map.inner())
      }
      _ => unknown_acts.push(key)
    }
  }
  { exp, mesos, items, unknown_acts }
}

///|
impl @json.FromJson for ActItem with from_json(json, path) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "expect object"))
  }
  let id : NumbericInt = @json.from_json(obj.get("id").or(Json::null()), path~)
  let count : Nullable[NumbericInt] = @json.from_json(
    obj.get("count").or(Json::null()),
    path=path.add_key("count"),
  )
  let period : Nullable[NumbericInt] = @json.from_json(
    obj.get("period").or(Json::null()),
    path=path.add_key("period"),
  )
  {
    id: id.inner(),
    count: count.inner().map(fn(c) { c.inner() }),
    period: period.inner().map(fn(p) { p.inner() }),
  }
}

///|
typealias @resource.IntMap
