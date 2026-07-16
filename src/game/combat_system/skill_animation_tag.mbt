///|
fn sanitize_skill_animation_tag_part(part : String) -> String {
  if part == "" {
    abort("empty skill animation tag path segment")
  }
  part
  .replace(old="/", new="_")
  .replace(old="\\", new="_")
  .replace(old=" ", new="_")
}

///|
fn skill_animation_tag(parts : Array[String]) -> String {
  if parts.is_empty() {
    abort("empty skill animation tag path")
  }
  let out = [ for part in parts => sanitize_skill_animation_tag_part(part) ]
  out.join("__")
}

///|
test "skill animation tag joins relative path with double underscore" {
  inspect(skill_animation_tag(["level", "1", "ball"]), content="level__1__ball")
  inspect(
    skill_animation_tag(["level", "1", "hit", "0"]),
    content="level__1__hit__0",
  )
  inspect(skill_animation_tag(["effect0"]), content="effect0")
}
