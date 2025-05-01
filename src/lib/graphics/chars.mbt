pub fn Charset::new(
  src : @resource.NxNode,
  alignment : CharsetAlignment
) -> Charset {
  let chars = Map::new()
  for sub in src {
    let name = sub.name()
    if name.is_empty() {
      continue
    }
    match sub.get_bitmap() {
      Some(_) => ()
      None => continue
    }
    let mut c = name[0]
    if c == '\\' {
      c = '/'
    }
    chars.set(c, Texture::from_resource(sub))
  }
  { chars, alignment }
}
