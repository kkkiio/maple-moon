pub struct Context {
  variable_map : Map[String, (String) -> String!]
}

pub fn format_text(text : String, ctx : Context) -> String! {
  let chunk = []
  for offset = 0; offset < text.length(); {
    let first = text.index_of("#", from=offset)
    if first < 0 {
      chunk.push(text.substring(start=offset))
      break
    }
    let second = text.index_of("#", from=first + 1)
    if second < 0 {
      chunk.push(text.substring(start=offset))
      break
    }
    chunk.push(text.substring(start=offset, end=first))
    let placeholder = text.substring(start=first + 1, end=second)
    match
      ctx.variable_map
      .iter()
      .find_first(fn(entry) { placeholder.starts_with(entry.0) }) {
      Some((key, value)) =>
        chunk.push(value!(placeholder.substring(start=key.length())))
      None => chunk.push(text.substring(start=first, end=second + 1)) // unknown placeholder
    }
    continue second + 1
  }
  chunk.join("")
}
