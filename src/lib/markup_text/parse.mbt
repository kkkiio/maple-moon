///| Parse markup text
pub fn parse_markup(
  text : String,
  tag_map : Map[Char, MarkupType]
) -> Array[Node]!ParseError {
  let nodes = []
  let mut rest_text = text[:]
  while not(rest_text.is_empty()) {
    guard rest_text.find("#") is Some(markup_start) else {
      nodes.push(to_text(rest_text))
      break
    }
    if markup_start > 0 {
      nodes.push(to_text(rest_text.charcodes(end=markup_start)))
    }
    let tag = rest_text.char_at(markup_start + 1)
    guard tag_map.get(tag) is Some(tag_type) else { raise UnknownTag(tag) }
    match tag_type {
      MarkupType::SelfClosing => {
        nodes.push(Node::Tag(tag, ""))
        rest_text = rest_text.charcodes(start=markup_start + 2)
      }
      MarkupType::Pair => {
        rest_text = rest_text.charcodes(start=markup_start + 2)
        guard rest_text.find("#") is Some(markup_end) else {
          // TODO: allow # in text?
          raise MissingMarkupClose
        }
        let payload = rest_text.charcodes(end=markup_end)
        nodes.push(Node::Tag(tag, payload))
        rest_text = rest_text.charcodes(start=markup_end + 1)
      }
    }
  }
  nodes
}

///|
fn to_text(text : @string.StringView) -> Node {
  Node::Text(
    text.replace_all(old="\\r", new="\r").replace_all(old="\\n", new="\n"),
  )
}

///|
pub(all) enum MarkupType {
  SelfClosing // '#' tag_name
  Pair // '#' tag_name payload? '#'
}

///|
pub enum Node {
  Text(@string.StringView)
  Tag(Char, @string.StringView)
}

///|
pub(all) type! ParseError {
  UnknownTag(Char)
  MissingMarkupClose
} derive(Show)
