///|
pub struct QuestFFI {
  id : Int
  name : String
  desc : String
  progress : String
  completed_time : Double
}

///|
pub fn watch_quest_log_ffi(
  mod : Module,
  callback : (Array[QuestFFI]) -> Bool
) -> Unit {
  let cb2 = fn(quest_log : PlayerQuestLog) {
    let quests = []
    for id, quest in quest_log.in_progress {
      let ref_name_provider = {
        quest: InProgress(quest),
        ref_render: mod.ref_render,
        inventory: mod.inventory,
      }
      let markup_desc = quest.quest_info.descriptions.get(quest.phase).or("")
      let desc = try parse_quest_desc!(markup_desc, ref_name_provider~) catch {
        err => {
          @log.warn({ "desc": markup_desc, "err": err }, "failed to parse desc")
          markup_desc
        }
      }
      quests.push({
        id,
        name: quest.quest_info.name,
        desc,
        progress: quest.progress_data,
        completed_time: 0,
      })
    }
    for id, quest in quest_log.completed {
      let ref_name_provider = {
        quest: Completed(quest),
        ref_render: mod.ref_render,
        inventory: mod.inventory,
      }
      let markup_desc = quest.quest_info.descriptions.last().or("")
      let desc = try parse_quest_desc!(markup_desc, ref_name_provider~) catch {
        err => {
          @log.warn({ "desc": markup_desc, "err": err }, "failed to parse desc")
          markup_desc
        }
      }
      quests.push({
        id,
        name: quest.quest_info.name,
        desc,
        progress: "",
        completed_time: quest.completion_time.to_double(),
      })
    }
    callback(quests)
  }
  if not(cb2(mod.player_quest_log.val)) {
    return
  }
  mod.quest_log_listeners.push(cb2)
}

///|
pub fn parse_quest_desc(
  s : String,
  ref_name_provider~ : &QuestTextRefProvider = TestQuestRefNameProvider::default()
) -> String! {
  let tag_replace_map = {
    'R': fn!(style, v) { ref_name_provider.get_progress!(style, v) },
    'o': fn!(style, v) { ref_name_provider.get_mob(style, v) },
    'p': fn!(style, v) { ref_name_provider.get_npc(style, v) },
    'a': fn!(style, v) { ref_name_provider.get_check(style, v) },
    'm': fn!(style, v) { ref_name_provider.get_map_name(style, v) },
    't': fn!(style, v) { ref_name_provider.get_item_name(style, v) },
    'c': fn!(style, v) { ref_name_provider.get_item_count(style, v) },
    '@': fn!(style, v) { ref_name_provider.get_npc(style, v.trim_end(":")) },
  }
  let node = @markup_text.parse_markup!(s, tag_map)
  let html = @markup_text.to_html!(
    node,
    { color: ColorName::BLACK, bold: false },
    @markup_text.color_map,
    tag_replace_map,
  )
  html
}

///|
trait QuestTextRefProvider {
  get_progress(Self, Style, @string.View) -> String!
  get_mob(Self, Style, @string.View) -> String!
  get_npc(Self, Style, @string.View) -> String!
  get_check(Self, Style, @string.View) -> String!
  get_map_name(Self, Style, @string.View) -> String!
  get_item_name(Self, Style, @string.View) -> String!
  get_item_count(Self, Style, @string.View) -> String!
}

///|
priv struct RefProviderImpl {
  quest : StartedQuest
  ref_render : @markup_text.RefRender
  inventory : @inventory.Inventory
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_progress(self, _, v) {
  let quest = self.quest
  let info_number = @strconv.parse_int!(v.to_string())
  guard quest is InProgress(quest)  // TODO: support completed quest?
  if quest.info_number_progress_map.get(info_number) is Some(progress) {
    "<a href=\"#\">\{progress}</a>"
  } else {
    fail!("no progress data: \{info_number}")
  }
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_mob(self, _, v) {
  self.ref_render.get_mob_name(v)
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_npc(self, _, v) {
  self.ref_render.get_npc_name(v)
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_check(self, _, v) {
  let quest = self.quest
  guard quest is InProgress(quest)  // TODO: support completed quest?
  let quest_id = quest.quest_id.to_string()
  guard v.has_prefix(quest_id) else { fail!("unknown check: \{v}") }
  let check_no = @strconv.parse_int!(
    v.charcodes(start=quest_id.length()).to_string(),
  ) // start from 1
  guard quest.checks.get(quest.phase) is Some(checks) else {
    fail!("no checks: \{quest_id}")
  }
  let index = check_no - 1
  guard checks.monster_hunts.get(index) is Some(check) else {
    fail!("no check: \{check_no}")
  }
  let progress_data = quest.get_phase_progress(quest.phase)
  check_mob_progress_data!(progress_data)
  let current_count = @strconv.parse_int!(
    progress_data.substring(start=index * 3, end=index * 3 + 3),
    base=10,
  )
  "\{current_count} / \{check.count}"
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_map_name(self, _, v) {
  self.ref_render.get_map_name(v)
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_item_name(self, _, v) {
  self.ref_render.get_item_name(v)
}

///|
impl QuestTextRefProvider for RefProviderImpl with get_item_count(self, _, v) {
  let item_id = @strconv.parse_int!(v.to_string())
  let count = self.inventory.get_item_count(item_id)
  count.to_string()
}

///|
type TestQuestRefNameProvider Unit derive(Default)

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_progress(
  _,
  _,
  progress_id
) {
  "<progress>\{progress_id}</progress>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_mob(
  _,
  _,
  mob_id
) {
  "<mob>\{mob_id}</mob>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_npc(
  _,
  _,
  npc_id
) {
  "<npc>\{npc_id}</npc>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_map_name(
  _,
  _,
  map_id
) {
  "<map>\{map_id}</map>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_item_name(
  _,
  _,
  item_id
) {
  "<item>\{item_id}</item>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_item_count(
  _,
  _,
  item_id
) {
  "<count>\{item_id}</count>"
}

///|
impl QuestTextRefProvider for TestQuestRefNameProvider with get_check(_, _, v) {
  "<check>\{v}</check>"
}

///| #R[info_number]#
let info_number_tag : Char = 'R'

///| #o[mobid]# - Shows the name of the mob.
let mob_tag : Char = 'o'

///| #a[quest_id][number]# - monster hunt check count
let mob_count_tag : Char = 'a'

///| #c[itemid]# Shows how many [itemid] the player has in their inventory.
let item_count_tag : Char = 'c'

///|
let tag_map : Map[Char, @markup_text.MarkupType] = @markup_text.color_map
  .keys()
  .map(fn(c : Char) { (c, @markup_text.MarkupType::SelfClosing) })
  .concat(
    @markup_text.font_weight_tag_map
    .keys()
    .map(fn(c : Char) { (c, @markup_text.MarkupType::SelfClosing) }),
  )
  .concat(
    [
      (info_number_tag, @markup_text.MarkupType::Pair),
      (mob_tag, @markup_text.MarkupType::Pair),
      (mob_count_tag, @markup_text.MarkupType::Pair),
      (item_count_tag, @markup_text.MarkupType::Pair),
      (@markup_text.npc_tag.0, @markup_text.npc_tag.1),
      (@markup_text.map_tag.0, @markup_text.map_tag.1),
      (@markup_text.item_tag.0, @markup_text.item_tag.1),
      ('@', @markup_text.MarkupType::Pair), // no sure #@id:# is a pair tag
    ].iter(),
  )
  |> Map::from_iter

///|
typealias ColorName = @struct.ColorName

///|
typealias Style = @markup_text.Style

///|
test "parse quest desc 1" {
  let desc = parse_quest_desc!(
    "Let's begin the exploration! You can earn the #b<Beginner Explorer>#k title by exploring the villages in Victoria.",
  )
  inspect!(
    desc,
    content=
      #|<span style="color: black">Let&#039;s begin the exploration! You can earn the </span><span style="color: blue">&lt;Beginner Explorer&gt;</span><span style="color: black"> title by exploring the villages in Victoria.</span>
    ,
  )
}

///|
test "parse quest bold desc" {
  let desc = parse_quest_desc!(
    "#b#eTitle - Beginner Explorer#k#n\\r\\nExplore the 20 main regions of Victoria Island.\\r\\n#b● Status : #R27010# / 20 Completed#k",
  )
  inspect!(
    desc,
    content=
      #|<span style="color: blue, font-weight: bold;">Title - Beginner Explorer</span><span style="color: black"></span><br/>
      #|<span style="color: black">Explore the 20 main regions of Victoria Island.</span><br/>
      #|<span style="color: black"></span><span style="color: blue">● Status : </span><progress>27010</progress><span style="color: blue"> / 20 Completed</span>
    ,
  )
}

///|
test "parse monster hunt check count" {
  let q1016_1_desc = parse_quest_desc!(
    "I decided to get trained under the Famous Sword-Master, Mai, in Amherst. I guess hunting the weakest monsters is a good idea. Should I hunt Snail, Blue Snail, and Shroom in order?\\n\\n#o100100# #r#a10161# #k\\n#o100101#  #r#a10162# #k\\n#o120100# #r#a10163##k\\n\\n Ah, Mai told me to meet with #p20002# in Southperry and try training together...",
  )
  inspect!(
    q1016_1_desc,
    content=
      #|<span style="color: black">I decided to get trained under the Famous Sword-Master, Mai, in Amherst. I guess hunting the weakest monsters is a good idea. Should I hunt Snail, Blue Snail, and Shroom in order?</span><br/>
      #|<span style="color: black"></span><br/>
      #|<span style="color: black"></span><mob>100100</mob> <check>10161</check> <br/>
      #|<mob>100101</mob>  <check>10162</check> <br/>
      #|<mob>120100</mob> <check>10163</check><span style="color: black"></span><br/>
      #|<span style="color: black"></span><br/>
      #|<span style="color: black"> Ah, Mai told me to meet with </span><npc>20002</npc><span style="color: black"> in Southperry and try training together...</span>
    ,
  )
}

///|
test "parse map name" {
  let desc = parse_quest_desc!(
    "She says there are way too many Snails and would like you to eliminate 10 #rRed Snails#k and 10 #rBlue Snails#k.\\n\\nLet's report back to #bAyan#k in #b#m102000000##k upon completion.",
  )
  inspect!(
    desc,
    content=
      #|<span style="color: black">She says there are way too many Snails and would like you to eliminate 10 </span><span style="color: red">Red Snails</span><span style="color: black"> and 10 </span><span style="color: red">Blue Snails</span><span style="color: black">.</span><br/>
      #|<span style="color: black"></span><br/>
      #|<span style="color: black">Let&#039;s report back to </span><span style="color: blue">Ayan</span><span style="color: black"> in </span><map>102000000</map><span style="color: black"> upon completion.</span>
    ,
  )
}

///|
test "parse item" {
  let desc = parse_quest_desc!(
    "Can you get me #b#e30#n #b#t4000003#es#k and #b#e50#n #t4000018#s#k? I'm trying to remodel my house and make it bigger ... If you can do it, I'll hook you up with a nice #bshield#k that I don't really need ... You'll get plenty if you take down the ones that look like trees.",
  )
  inspect!(
    desc,
    content=
      #|<span style="color: black">Can you get me </span><span style="color: blue, font-weight: bold;">30</span> <item>4000003</item><span style="color: blue">es</span><span style="color: black"> and </span><span style="color: blue, font-weight: bold;">50</span> <item>4000018</item><span style="color: blue">s</span><span style="color: black">? I&#039;m trying to remodel my house and make it bigger ... If you can do it, I&#039;ll hook you up with a nice </span><span style="color: blue">shield</span><span style="color: black"> that I don&#039;t really need ... You&#039;ll get plenty if you take down the ones that look like trees.</span>
    ,
  )
}

///|
pub fn forfeit_quest_ffi(mod : Module, quest_id : Int) -> Unit {
  let msg = QuestActionMessage::ForfeitQuest(quest_id~)
  mod.network.send_message(msg)
}
