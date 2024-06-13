// Prefix an id with zeros so that it has the minimum specified length
pub fn extend_id(id : Int, length : Int) -> String {
  let strid = id.to_string()
  if strid.length() < length {
    let buf = Buffer::make(length)
    Iter::repeat('0').take(length - strid.length()).iter(
      fn(c) { buf.write_char(c) },
    )
    buf.write_string(strid)
    buf.to_string()
  } else {
    strid
  }
}
