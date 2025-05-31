///|
pub fn to_html(
  nodes : Array[Node],
  style : Style,
  color_map : Map[Char, ColorName],
  tag_replace_map : Map[Char, (Style, @string.View) -> @string.View!]
) -> String! {
  let mut current_style = style
  let builder = StringBuilder::new()
  for node in nodes {
    match node {
      Node::Text(text) => write_text(builder, text, current_style)
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
pub fn write_text(
  builder : StringBuilder,
  text : @string.View,
  style : Style
) -> Unit {
  let no_span = text.is_blank()
  let text = text
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\n", new="<br>\n")
  if no_span {
    builder.write_string(text.to_string())
  } else {
    builder.write_string(
      "<span style=\"\{style.to_css_style()}\">\{text}</span>",
    )
  }
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
