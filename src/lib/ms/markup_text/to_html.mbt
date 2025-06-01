///|
pub fn to_html(
  nodes : Array[Node],
  style : Style,
  color_map : Map[Char, ColorName],
  tag_replace_map : Map[Char, (Style, @string.View) -> String!],
  trim_end_newline~ : Bool = false
) -> String! {
  let mut current_style = style
  let builder = StringBuilder::new()
  for i, node in nodes {
    match node {
      Node::Text(text) =>
        write_text_as_html(
          builder,
          text,
          current_style,
          trim_end_newline=trim_end_newline && i == nodes.length() - 1,
        )
      Node::Tag(tag, payload) =>
        if font_weight_tag_map.get(tag) is Some(b) {
          current_style = { ..current_style, bold: b }
        } else if color_map.get(tag) is Some(color) {
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
  builder.to_string()
}

///|
pub fn write_text_as_html(
  builder : StringBuilder,
  text : @string.View,
  style : Style,
  trim_end_newline~ : Bool = false
) -> Unit {
  if text.is_blank() {
    let mut text = text.replace_all(old="\r\n", new="\n")
    if trim_end_newline {
      text = text.trim_end("\n")
    }
    text = text.replace_all(old="\n", new="<br/>\n")
    builder.write_string(text.to_string())
    return
  }
  // split lines
  let lines = text.to_string().replace_all(old="\r\n", new="\n").split("\n")
  for
    line in lines
    .map(fn(line) {
      "<span style=\"\{style.to_css_style()}\">\{escape_html(line.to_string())}</span>"
    })
    .intersperse("<br/>\n") {
    builder.write_string(line)
  }
}

///|
fn escape_html(raw : String) -> String {
  raw
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#039;")
}

///|
pub(all) struct Style {
  color : ColorName
  bold : Bool
}

///|
pub fn Style::to_css_style(self : Style) -> String {
  if self.bold {
    "color: \{self.color}, font-weight: bold;"
  } else {
    "color: \{self.color}"
  }
}
