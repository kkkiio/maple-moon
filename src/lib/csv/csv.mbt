///|
/// Parse one CSV line.
///
/// Supports:
/// - quoted field: `"a,b"`
/// - escaped quote: `""` inside quoted fields
pub fn parse_csv_line(line : String) -> Array[String] {
  let fields : Array[String] = []
  let mut current = StringBuilder::new()
  let mut in_quotes = false
  let chars = line.to_array()

  let mut i = 0
  while i < chars.length() {
    let c = chars[i]
    if c == '"' {
      if in_quotes && i + 1 < chars.length() && chars[i + 1] == '"' {
        current.write_char('"')
        i = i + 1
      } else {
        in_quotes = not(in_quotes)
      }
    } else if c == ',' && not(in_quotes) {
      fields.push(current.to_string())
      current = StringBuilder::new()
    } else {
      current.write_char(c)
    }
    i = i + 1
  }
  fields.push(current.to_string())
  fields
}

///|
/// Strip optional surrounding double quotes and trim spaces.
pub fn strip_quotes(s : String) -> String {
  match s.trim() {
    ['"', .. inner, '"'] => inner.to_string()
    val => val.to_string()
  }
}

///|
/// Build header name to index map from a CSV header line.
pub fn parse_csv_header(line : String) -> Map[String, Int] {
  let out : Map[String, Int] = {}
  let fields = parse_csv_line(line)
  for i = 0; i < fields.length(); i = i + 1 {
    let key = strip_quotes(fields[i])
    if not(key.is_empty()) {
      out[key] = i
    }
  }
  out
}

///|
/// Parse an integer field by header key.
///
/// Raises when column does not exist, is missing on the row, or is not an integer.
pub fn parse_csv_int_field(
  fields : Array[String],
  header : Map[String, Int],
  name : String,
  line_no : Int,
  file_name : String,
) -> Int raise {
  guard header.get(name) is Some(idx) else {
    fail("missing csv column '\{name}' in \{file_name}")
  }
  if idx >= fields.length() {
    fail("csv line \{line_no} missing column '\{name}' in \{file_name}")
  }
  @strconv.parse_int(strip_quotes(fields[idx])) catch {
    _ => fail("invalid int '\{name}' at line \{line_no} in \{file_name}")
  }
}

///|
/// Parse an optional integer field by header key.
///
/// Returns `default` when the column is absent, missing, or invalid.
pub fn parse_csv_int_field_or_default(
  fields : Array[String],
  header : Map[String, Int],
  name : String,
  default : Int,
) -> Int {
  match header.get(name) {
    Some(idx) =>
      if idx < fields.length() {
        @strconv.parse_int(strip_quotes(fields[idx])) catch {
          _ => default
        }
      } else {
        default
      }
    None => default
  }
}
