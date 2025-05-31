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
      let markup_desc = quest.quest_info.descriptions.get(quest.phase).or("")
      let desc = try
        parse_quest_desc!(
          markup_desc,
          progress_provider=fn(_, v) {
            let info_number = @strconv.parse_int!(v.to_string())
            if quest.info_number_progress_map.get(info_number) is Some(progress) {
              "<a href=\"#\">\{progress}</a>"
            } else {
              fail!("no progress data: \{info_number}")
            }
          },
          mod_provider=fn(_, v) { mod.name_loader.get_mob_name(v) },
          npc_provider=fn(_, v) { mod.name_loader.get_npc_name(v) },
          check_provider=fn(_, v) {
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
          },
          map_provider=fn(_, v) { mod.name_loader.get_map_name!(v).to_string() },
          item_provider=fn(_, v) {
            mod.name_loader.get_item_name(v).to_string()
          },
        ) catch {
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
      let markup_desc = quest.quest_info.descriptions.last().or("")
      let desc = try parse_quest_desc!(markup_desc) catch {
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
fn parse_quest_desc(
  s : String,
  progress_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  mod_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  npc_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  check_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  map_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  item_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v }
) -> String! {
  let tag_replace_map = {
    'R': progress_provider,
    'o': mod_provider,
    'p': npc_provider,
    'a': check_provider,
    'm': map_provider,
    't': item_provider,
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

///| #R[info_number]#
let info_number_tag : Char = 'R'

///| #o[mobid]# - Shows the name of the mob.
let mob_tag : Char = 'o'

///| #a[quest_id][number]# - monster hunt check count
let a_tag : Char = 'a'

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
      (a_tag, @markup_text.MarkupType::Pair),
      (@markup_text.npc_tag.0, @markup_text.npc_tag.1),
      (@markup_text.map_tag.0, @markup_text.map_tag.1),
      (@markup_text.item_tag.0, @markup_text.item_tag.1),
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
      #|<span style="color: black">Let's begin the exploration! You can earn the </span><span style="color: blue"><Beginner Explorer></span><span style="color: black"> title by exploring the villages in Victoria.</span>
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
      #|<span style="color: blue, font-weight: bold;">Title - Beginner Explorer</span><span style="color: black"><br>
      #|Explore the 20 main regions of Victoria Island.<br>
      #|</span><span style="color: blue">● Status : </span>27010<span style="color: blue"> / 20 Completed</span>
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
      #|<span style="color: black">I decided to get trained under the Famous Sword-Master, Mai, in Amherst. I guess hunting the weakest monsters is a good idea. Should I hunt Snail, Blue Snail, and Shroom in order?<br>
      #|<br>
      #|</span>100100 10161 <br>
      #|100101  10162 <br>
      #|120100 10163<span style="color: black"><br>
      #|<br>
      #| Ah, Mai told me to meet with </span>20002<span style="color: black"> in Southperry and try training together...</span>
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
      #|<span style="color: black">She says there are way too many Snails and would like you to eliminate 10 </span><span style="color: red">Red Snails</span><span style="color: black"> and 10 </span><span style="color: red">Blue Snails</span><span style="color: black">.<br>
      #|<br>
      #|Let's report back to </span><span style="color: blue">Ayan</span><span style="color: black"> in </span>102000000<span style="color: black"> upon completion.</span>
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
      #|<span style="color: black">Can you get me </span><span style="color: blue, font-weight: bold;">30</span> 4000003<span style="color: blue">es</span><span style="color: black"> and </span><span style="color: blue, font-weight: bold;">50</span> 4000018<span style="color: blue">s</span><span style="color: black">? I'm trying to remodel my house and make it bigger ... If you can do it, I'll hook you up with a nice </span><span style="color: blue">shield</span><span style="color: black"> that I don't really need ... You'll get plenty if you take down the ones that look like trees.</span>
    ,
  )
}

///|
pub fn forfeit_quest_ffi(mod : Module, quest_id : Int) -> Unit {
  let msg = QuestActionMessage::ForfeitQuest(quest_id~)
  mod.network.send_message(msg)
}
