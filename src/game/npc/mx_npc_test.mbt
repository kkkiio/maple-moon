///|
test "parse_mx_npc_basic" {
  let src : Json = {
    "info": { "speak": { "0": "n0", "1": "n1" } },
    "animations_path": "animation.json",
  }
  let npc : MxNpc = @json.from_json(src)
  debug_inspect(
    (npc.animations_path, npc.info.speak_keys),
    content=(
      #|("animation.json", ["n0", "n1"])
    ),
  )
}

///|
test "parse_mx_npc_link_and_scripted" {
  let src : Json = {
    "info": { "link": "1021000", "script": { "0": { "script": "foo" } } },
    "animations_path": "animation.json",
  }
  let npc : MxNpc = @json.from_json(src)
  debug_inspect(
    (npc.info.link, npc.info.scripted),
    content=(
      #|(Some("1021000"), true)
    ),
  )
}

///|
test "parse_mx_npc_reject_missing_animations_path" {
  let src : Json = { "info": { "speak": { "0": "n0" } } }
  let _ : MxNpc = @json.from_json(src) catch { _ => return }
  fail("expected parse error for missing animations_path")
}
