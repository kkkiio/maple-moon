///|
pub fn ellipsis(s : String, max_len : Int, ellipsis~ : String = "..") -> String {
  if s.length() > max_len {
    s.substring(end=max_len - ellipsis.length()) + ellipsis
  } else {
    s
  }
}

///|
let hex_digits = [
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
  digits.rev_inplace()
  "0x" + digits.join("")
}
