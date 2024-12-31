///|
pub fn ellipsis(s : String, max_len : Int, ellipsis~ : String = "..") -> String {
  if s.length() > max_len {
    s.substring(end=max_len - ellipsis.length()) + ellipsis
  } else {
    s
  }
}
