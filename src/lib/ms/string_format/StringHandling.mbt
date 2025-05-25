///| Prefix an id with zeros so that it has the minimum specified length
pub fn extend_id(id : Int, length : Int) -> String {
  let strid = id.to_string()
  if strid.length() < length {
    let buf = StringBuilder::new(size_hint=length)
    Iter::repeat('0')
    .take(length - strid.length())
    .each(fn(c) { buf.write_char(c) })
    buf.write_string(strid)
    buf.to_string()
  } else {
    strid
  }
}

///| Format a number so that each 3 decimal points are seperated by a ',' character.
pub fn format_decimal_separator(num : Int) -> String {
  if num < 0 {
    return abort("num must be positive")
  }
  if num == 0 {
    return "0"
  }
  let buf = StringBuilder::new()
  let mut count = 0
  for acc = num; acc > 0; acc = acc / 10 {
    let digit = acc % 10
    if count % 3 == 0 && count != 0 {
      buf.write_char(',')
    }
    buf.write_char(Int::unsafe_to_char(digit + 48))
    count += 1
  }
  buf.to_string().rev()
}
