///|
pub(all) struct TalkContent {
  text_html : String // Assume no text after selections
  selections : TalkSelections?
} derive(Show)

///|
pub(all) struct TalkSelections {
  color : @struct.ColorName
  selections : Array[(Int, String)]
} derive(Eq, Show, ToJson)

///|
test "test text" {
  let markup_text = "Take this ship and you'll head off to a bigger continent. For #e150 mesos#n, I'll take you to #bVictoria Island#k. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?"
  let result = parse_talk_content!(markup_text, { fn_map: {} })
  assert_true!(result.selections.is_empty())
  inspect!(
    result.text_html,
    content=
      #|Take this ship and you'll head off to a bigger continent. For <span style="font-weight: bold">150 mesos</span>, I'll take you to <span style="color: blue">Victoria Island</span>. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?
    ,
  )
}

///|
test "test selections" {
  let template =
    #|We have a special 90% discount for beginners.Choose your destination, for fees will change from place to place.#b
    #|#L0##m104000000# (100 mesos)#l
    #|#L1##m102000000# (100 mesos)#l
    #|#L2##m100000000# (100 mesos)#l
    #|#L3##m103000000# (100 mesos)#l
    #|#L4##m120000000# (80 mesos)#l
  let result = parse_talk_content!(template, {
    fn_map: { 'm': fn(v) { "test_map_\{v}_name" } },
  })
  @json.inspect!(result.selections, content=[
    {
      "color": "blue",
      "selections": [
        [0, "test_map_104000000_name (100 mesos)"],
        [1, "test_map_102000000_name (100 mesos)"],
        [2, "test_map_100000000_name (100 mesos)"],
        [3, "test_map_103000000_name (100 mesos)"],
        [4, "test_map_120000000_name (80 mesos)"],
      ],
    },
  ])
  inspect!(
    result.text_html,
    content="We have a special 90% discount for beginners.Choose your destination, for fees will change from place to place.",
  )
}

///|
test "test no options" {
  let template = "Hi there! This cab is for VIP customers only. Instead of just taking you to different towns like the regular cabs, we offer a much better service worthy of VIP class. It's a bit pricey, but... for only 10,000 mesos, we'll take you safely to the \r\n#bAnt Tunnel#k."
  let result = parse_talk_content!(template, { fn_map: {} })
  assert_eq!(result.selections, None)
  inspect!(
    result.text_html,
    content=
      #|Hi there! This cab is for VIP customers only. Instead of just taking you to different towns like the regular cabs, we offer a much better service worthy of VIP class. It's a bit pricey, but... for only 10,000 mesos, we'll take you safely to the <br/><span style="color: blue">Ant Tunnel</span>.
    ,
  )
}

///| NPC Markups:
/// #b = Blue text.
/// #c[itemid]# Shows how many [itemid] the player has in their inventory.
/// #d = Purple text.
/// #e = Bold text.
/// #f[imagelocation]# - Shows an image inside the .wz files.
/// #g = Green text.
/// #h # - Shows the name of the player.
/// #i[itemid]# - Shows a picture of the item.
/// #k = Black text.
/// #l - Selection close.
/// #m[mapid]# - Shows the name of the map.
/// #n = Normal text (removes bold).
/// #o[mobid]# - Shows the name of the mob.
/// #p[npcid]# - Shows the name of the NPC.
/// #q[skillid]# - Shows the name of the skill.
/// #r = Red text.
/// #s[skillid]# - Shows the image of the skill.
/// #t[itemid]# - Shows the name of the item.
/// #v[itemid]# - Shows a picture of the item.
/// #x - Returns "0%" (need more information on this).
/// #z[itemid]# - Shows the name of the item.
/// #B[%]# - Shows a 'progress' bar.
/// #F[imagelocation]# - Shows an image inside the .wz files.
/// #L[number]# Selection open.
/// \r\n - Moves down a line.
fn parse_talk_content(
  text : String,
  ctx : VariableContext
) -> TalkContent!ParseTalkError {
  let text = text.replace_all(old="\r\n", new="\n") // normalize newlines
  // Split text into normal text and selections
  let selection_start = text.index_of("#L")
  let (normal_text, selection_text) = if selection_start < 0 {
    (text, "")
  } else {
    (
      text.substring(start=0, end=selection_start).trim_end("\n").to_string(),
      text.substring(start=selection_start),
    )
  }
  let (normal_text, color) = if normal_text.ends_with("#b") { // TODO: more color support
    (normal_text.trim_end("#b"), @struct.ColorName::BLUE)
  } else {
    (normal_text, @struct.ColorName::BLACK)
  }
  let text_html = parse_text!(
    ctx,
    normal_text.replace_all(old="\n", new="<br/>").to_string(),
  )
  if selection_text.is_empty() {
    return { text_html, selections: None }
  }
  let selections = []
  for line in selection_text.split("\n") {
    let selection = parse_selection!(ctx, line.to_string())
    selections.push(selection)
  }
  { text_html, selections: Some({ color, selections }) }
}

///| Parse text without selections.
fn parse_text(ctx : VariableContext, text : String) -> String!ParseTalkError {
  let chunk = []
  let mut color = @struct.ColorName::BLACK
  let mut bold = false
  for offset = 0; offset < text.length(); {
    let markup_start = text.index_of("#", from=offset)
    if markup_start < 0 {
      chunk.push(text.substring(start=offset))
      break
    }
    fn push_last_chunk() {
      if offset != markup_start {
        let text = text.substring(start=offset, end=markup_start)
        let style = []
        if color != @struct.ColorName::BLACK {
          style.push("color: \{color.css_name()}")
        }
        if bold {
          style.push("font-weight: bold")
        }
        let html = if style.is_empty() {
          text
        } else {
          let style_str = style |> String::concat(separator=";")
          "<span style=\"\{style_str}\">\{text}</span>"
        }
        chunk.push(html)
      }
    }

    // Handle color
    match color_map.get(text[markup_start + 1]) {
      Some(color_name) => {
        push_last_chunk()
        color = color_name
        continue markup_start + 2
      }
      None => ()
    }
    // Handle font
    match text[markup_start + 1] {
      'e' => {
        push_last_chunk()
        bold = true
        continue markup_start + 2
      }
      'n' => {
        push_last_chunk()
        bold = false
        continue markup_start + 2
      }
      _ => ()
    }
    // Handle variable
    let markup_end = text.index_of("#", from=markup_start + 1)
    if markup_end < 0 {
      raise ParseTalkError("Missing markup close") // TODO: allow # in text
    }
    push_last_chunk()
    let variable = text.substring(start=markup_start + 1, end=markup_end)
    match ctx.fn_map.get(variable[0]) {
      Some(f) => {
        let var_value = f!(variable.substring(start=1))
        chunk.push(var_value)
      }
      None => raise ParseTalkError("Unknown variable: \{variable}")
    }
    continue markup_end + 1
  }
  chunk |> String::concat(separator="")
}

///|
fn parse_selection(
  ctx : VariableContext,
  line : String
) -> (Int, String)!ParseTalkError {
  if not(line.starts_with("#L")) {
    raise ParseTalkError("Missing selection open markup")
  }
  if not(line.ends_with("#l")) {
    raise ParseTalkError("Missing selection close markup")
  }
  let digit_start = 2
  let digit_end = line.index_of("#", from=digit_start)
  if digit_end < 0 {
    raise ParseTalkError("Missing selection index")
  }
  let digits = line.substring(start=digit_start, end=digit_end)
  let index = try {
    @strconv.parse_int!(digits, base=10)
  } catch {
    @strconv.StrConvError(_) =>
      raise ParseTalkError("invalid selection index: \{digits}")
  }
  let text = parse_text!(
    ctx,
    line.substring(start=digit_end + 1, end=line.length() - 2),
  )
  (index, text)
}

///| Replace placeholders in the text with the values from the context.
/// Placeholders are the text in the format of `#\{kind}\{payload}#`.
struct VariableContext {
  fn_map : Map[Char, (String) -> String!ParseTalkError] // kind -> payload -> value
}

///|
let color_map : Map[Char, @struct.ColorName] = {
  'b': @struct.ColorName::BLUE,
  'd': @struct.ColorName::VIOLET,
  'g': @struct.ColorName::GREEN,
  'k': @struct.ColorName::BLACK,
  'r': @struct.ColorName::RED,
}

///|
pub(all) type! ParseTalkError String derive(Show)
