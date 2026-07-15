///|
/// Parse markup text
pub fn parse_markup(
  text : String,
  tag_map : Map[Char, MarkupType],
) -> Array[Node] raise ParseError {
  let nodes = []
  for token in scan_markup(text, tag_map) {
    match token {
      MarkupToken::Text(text) => nodes.push(to_text(text))
      MarkupToken::Tag(tag, payload) => nodes.push(Node::Tag(tag, payload))
      MarkupToken::Unknown(tag, _) => raise UnknownTag(tag)
      MarkupToken::Incomplete(_) => raise MissingMarkupClose
    }
  }
  nodes
}

///|
/// Scan Maple markup while retaining unknown or incomplete source text.
///
/// Known tags are classified through `tag_map`. Unknown and incomplete tokens
/// keep their original view so tolerant renderers can display them verbatim.
///
/// # Example
/// ```moonbit nocheck
/// let tags = Map([('b', @markup_text.MarkupType::SelfClosing)])
/// inspect(@markup_text.scan_markup("#btext", tags).length(), content="2")
/// ```
pub fn scan_markup(
  text : String,
  tag_map : Map[Char, MarkupType],
) -> Array[MarkupToken] {
  let tokens = []
  let mut rest = text[:]
  while !rest.is_empty() {
    lexscan rest with longest {
      (re"^[^#]+" as plain_text, after=tail) => {
        tokens.push(MarkupToken::Text(plain_text))
        rest = tail
      }
      (re"^#." as marker, after=tail) => {
        let tag = marker.get_char(1).unwrap()
        match tag_map.get(tag) {
          Some(MarkupType::SelfClosing) => {
            tokens.push(MarkupToken::Tag(tag, ""))
            rest = tail
          }
          Some(MarkupType::Pair) =>
            lexscan tail with longest {
              (re"^[^#]*#" as encoded_payload, after=remaining) => {
                let payload = encoded_payload.view(
                  end_offset=encoded_payload.length() - 1,
                )
                tokens.push(MarkupToken::Tag(tag, payload))
                rest = remaining
              }
              _ => {
                tokens.push(MarkupToken::Incomplete(rest))
                rest = ""[:]
              }
            }
          None =>
            lexscan tail with longest {
              (re"^[^#]*#" as encoded_payload, after=remaining) => {
                tokens.push(
                  MarkupToken::Unknown(
                    tag,
                    rest.view(
                      end_offset=marker.length() + encoded_payload.length(),
                    ),
                  ),
                )
                rest = remaining
              }
              _ => {
                tokens.push(MarkupToken::Unknown(tag, rest))
                rest = ""[:]
              }
            }
        }
      }
      _ => {
        tokens.push(MarkupToken::Incomplete(rest))
        rest = ""[:]
      }
    }
  }
  tokens
}

///|
fn to_text(text : StringView) -> Node {
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
  Text(StringView)
  Tag(Char, StringView)
}

///|
/// A lossless token emitted by `scan_markup`.
pub enum MarkupToken {
  /// Plain text outside markup markers.
  Text(StringView)
  /// A known self-closing or paired tag and its payload.
  Tag(Char, StringView)
  /// An unknown tag together with its original source text.
  Unknown(Char, StringView)
  /// A trailing marker or known paired tag without a closing marker.
  Incomplete(StringView)
}

///|
pub(all) suberror ParseError {
  UnknownTag(Char)
  MissingMarkupClose
} derive(Debug)
