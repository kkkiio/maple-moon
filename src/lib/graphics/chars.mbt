///|
pub fn Charset::new(src : Json, alignment : CharsetAlignment) -> Charset raise {
  let chars = Map::new()
  guard src is Object(obj) else { return { chars, alignment } }
  for name, sub in obj {
    guard sub is { "__i": String(_), .. } else { continue }
    let mut c = name.get_char(0).unwrap()
    if c == '\\' {
      c = '/'
    }
    let tex : @resource.NxTexture = @json.from_json(sub)
    chars.set(c, tex)
  }
  { chars, alignment }
}
