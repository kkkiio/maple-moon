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
      let desc = try {
        parse_quest_desc!(markup_desc, progress_getter=fn(v) {
          let info_number = @strconv.parse_int!(v.to_string())
          if quest.info_number_progress_map.get(info_number) is Some(progress) {
            progress
          } else {
            @log.error({ "info_number": info_number }, "no progress data")
            ""
          }
        })
      } catch {
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
      let desc = try {
        parse_quest_desc!(markup_desc)
      } catch {
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
  if not(cb2(mod.player_quest_log)) {
    return
  }
  mod.quest_log_listeners.push(cb2)
}

///|
fn parse_quest_desc(
  s : String,
  progress_getter~ : (@string.StringView) -> @string.StringView! = fn(v) { v }
) -> String! {
  let node = @markup_text.parse_markup!(s, tag_map)
  let html = to_html!(
    node,
    ColorName::BLACK,
    @markup_text.color_map,
    progress_getter,
  )
  html
}

///|
let info_number_tag : Char = 'R'

///|
let tag_map : Map[Char, @markup_text.MarkupType] = @markup_text.color_map
  .keys()
  .map(fn(c : Char) { (c, @markup_text.MarkupType::SelfClosing) })
  .concat(
    @markup_text.font_weight_tag_map
    .keys()
    .map(fn(c : Char) { (c, @markup_text.MarkupType::SelfClosing) }),
  )
  .append((info_number_tag, @markup_text.MarkupType::Pair))
  |> Map::from_iter

///|
fn to_html(
  nodes : Array[@markup_text.Node],
  color : ColorName,
  color_map : Map[Char, ColorName],
  progress_getter : (@string.StringView) -> @string.StringView!
) -> String! {
  let mut bold = false
  let mut current_color = color
  let mut current_style = make_style(current_color, bold)
  let builder = StringBuilder::new()
  for node in nodes {
    match node {
      @markup_text.Node::Text(text) => {
        let text = text.replace_all(old="\r\n", new="<br>")
        builder.write_string("<span style=\"\{current_style}\">\{text}</span>")
      }
      @markup_text.Node::Tag(tag, payload) => {
        if @markup_text.font_weight_tag_map.get(tag) is Some(b) {
          bold = b
        } else if color_map.get(tag) is Some(color) {
          current_color = color
        } else if tag == info_number_tag {
          let progress = progress_getter!(payload)
          builder.write_string("<a href=\"#\">\{progress}</a>")
        } else {
          fail!("Unknown tag: \{tag}")
        }
        current_style = make_style(current_color, bold)
      }
    }
  }
  builder.to_string()
}

///|
fn make_style(color : ColorName, bold : Bool) -> String {
  if bold {
    "color: \{color}, font-weight: bold;"
  } else {
    "color: \{color}"
  }
}

///|
typealias ColorName = @struct.ColorName

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
    progress_getter=fn(info_number) {
      inspect!(info_number, content="27010")
      "10"
    },
  )
  inspect!(
    desc,
    content=
      #|<span style="color: blue, font-weight: bold;">Title - Beginner Explorer</span><span style="color: black"><br>Explore the 20 main regions of Victoria Island.<br></span><span style="color: blue">● Status : </span><a href="#">10</a><span style="color: blue"> / 20 Completed</span>
    ,
  )
}

///|
pub fn forfeit_quest_ffi(mod : Module, quest_id : Int) -> Unit {
  let msg = QuestActionMessage::ForfeitQuest(quest_id~)
  mod.network.send_message(msg)
}
