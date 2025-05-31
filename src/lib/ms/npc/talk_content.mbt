///|
pub(all) struct TalkContent {
  text_html : String // Assume no text after selections
  selections : Array[(ColorName, Int, String)]
} derive(Show)

///|
test "test text" {
  let markup_text = "Take this ship and you'll head off to a bigger continent. For #e150 mesos#n, I'll take you to #bVictoria Island#k. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?"
  let result = parse_talk_content!(markup_text)
  inspect!(result.selections, content="[]")
  inspect!(
    result.text_html,
    content=
      #|<span style="color: black">Take this ship and you'll head off to a bigger continent. For </span><span style="color: black, font-weight: bold;">150 mesos</span><span style="color: black">, I'll take you to </span><span style="color: blue">Victoria Island</span><span style="color: black">. The thing is, once you leave this place, you can't ever come back. What do you think? Do you want to go to Victoria Island?</span>
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
  let result = parse_talk_content!(template)
  @json.inspect!(result.selections, content=[
    ["blue", 0, "104000000<span style=\"color: blue\"> (100 mesos)</span>"],
    ["blue", 1, "102000000<span style=\"color: blue\"> (100 mesos)</span>"],
    ["blue", 2, "100000000<span style=\"color: blue\"> (100 mesos)</span>"],
    ["blue", 3, "103000000<span style=\"color: blue\"> (100 mesos)</span>"],
    ["blue", 4, "120000000<span style=\"color: blue\"> (80 mesos)</span>"],
  ])
  inspect!(
    result.text_html,
    content=
      #|<span style="color: black">We have a special 90% discount for beginners.Choose your destination, for fees will change from place to place.</span><br>
      #|

    ,
  )
}

///|
test "test no options" {
  let template = "Hi there! This cab is for VIP customers only. Instead of just taking you to different towns like the regular cabs, we offer a much better service worthy of VIP class. It's a bit pricey, but... for only 10,000 mesos, we'll take you safely to the \r\n#bAnt Tunnel#k."
  let result = parse_talk_content!(template)
  inspect!(result.selections, content="[]")
  inspect!(
    result.text_html,
    content=
      #|<span style="color: black">Hi there! This cab is for VIP customers only. Instead of just taking you to different towns like the regular cabs, we offer a much better service worthy of VIP class. It's a bit pricey, but... for only 10,000 mesos, we'll take you safely to the <br>
      #|</span><span style="color: blue">Ant Tunnel</span><span style="color: black">.</span>
    ,
  )
}

///|
fn parse_talk_content(
  text : String,
  mod_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  npc_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  map_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  item_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) { v },
  player_name_provider~ : (Style, @string.View) -> @string.View! = fn(_, v) {
    v
  }
) -> TalkContent! {
  let tag_replace_map = {
    'o': mod_provider,
    'p': npc_provider,
    'm': map_provider,
    't': item_provider,
    'h': player_name_provider,
  }
  let selections = []
  let mut opening_selection : (Int, Array[@markup_text.Node])? = None
  let mut trim_newline = false
  let mut current_style : Style = { color: ColorName::BLACK, bold: false }
  let builder = StringBuilder::new()
  let nodes = @markup_text.parse_markup!(text, tag_map)
  for node in nodes {
    match node {
      Tag('L', payload) => {
        if opening_selection is Some(_) {
          fail!("Nested selection open")
        }
        let index = try @strconv.parse_int!(payload.to_string(), base=10) catch {
          @strconv.StrConvError(_) =>
            raise ParseTalkError("invalid selection index: \{payload}")
        }
        opening_selection = Some((index, []))
      }
      Tag('l', _) => {
        guard opening_selection is Some((index, nodes)) else {
          fail!("Selection close without open")
        }
        opening_selection = None
        selections.push(
          (
            current_style.color,
            index,
            @markup_text.to_html(
              nodes, current_style, @markup_text.color_map, tag_replace_map,
            ),
          ),
        )
        trim_newline = true // trim newline after selection
      }
      Text(text) => {
        if opening_selection is Some((_, nodes)) {
          nodes.push(node)
          continue
        }
        if trim_newline && (text == "\r\n" || text == "\n") {
          continue
        }
        @markup_text.write_text(builder, text, current_style)
      }
      Tag(tag, payload) => {
        if opening_selection is Some((_, nodes)) {
          nodes.push(node)
          continue
        }
        if @markup_text.font_weight_tag_map.get(tag) is Some(b) {
          current_style = { ..current_style, bold: b }
        } else if @markup_text.color_map.get(tag) is Some(color) {
          current_style = { ..current_style, color, }
        } else {
          let replace_fn = tag_replace_map.get(tag)
          if replace_fn is Some(replace_fn) {
            let replaced = replace_fn(current_style, payload)
            builder.write_string(replaced.to_string())
          } else {
            fail!("Unknown tag: \{tag}")
          }
        }
      }
    }
  }
  let text_html = builder.to_string()
  { text_html, selections }
}

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
      (@markup_text.npc_tag.0, @markup_text.npc_tag.1),
      (@markup_text.map_tag.0, @markup_text.map_tag.1),
      (@markup_text.item_tag.0, @markup_text.item_tag.1),
      ('L', @markup_text.MarkupType::Pair), // #L[number]# Selection open.
      ('l', @markup_text.MarkupType::SelfClosing), // #l - Selection close.
    ].iter(),
  )
  |> Map::from_iter

///|
pub(all) type! ParseTalkError String derive(Show)

///|
typealias ColorName = @struct.ColorName

///|
typealias Style = @markup_text.Style
