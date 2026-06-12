///|
pub fn ellipsis(s : String, max_len : Int, ellipsis? : String = "..") -> String {
  if s.length() > max_len {
    s.view(end_offset=max_len - ellipsis.length()).to_owned() + ellipsis
  } else {
    s
  }
}

///|
let hex_digits : Array[String] = [
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
]

///|
pub fn to_hex_string(i : UInt) -> String {
  let mut i = i
  let digits = []
  while i > 0 {
    digits.push(hex_digits[(i & 0xF).reinterpret_as_int()])
    i = i >> 4
  }
  digits.rev_in_place()
  "0x" + digits.join("")
}

///|
/// Prefix an id with zeros so that it has the minimum specified length
pub fn stoi_left_pad0(id : Int, length : Int) -> String {
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

///|
/// Format a number so that each 3 decimal points are seperated by a ',' character.
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
