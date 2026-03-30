///|
test "parse_nx_npc_basic_animation_and_speak" {
  let src : Json = {
    "info": { "speak": { "0": "n0", "1": "n1" } },
    "stand": {
      "0": {
        "__i": "assets/images/Npc/1.png",
        "__w": 40,
        "__h": 79,
        "origin": [22, 79],
      },
    },
  }
  let npc : NxNpc = @json.from_json(src)
  inspect(npc.animations.contains("stand"), content="true")
  inspect(
    npc.info.speak_keys_by_state.get("info").unwrap_or([]),
    content="[\"n0\", \"n1\"]",
  )
}

///|
test "parse_nx_npc_link_field" {
  let src : Json = {
    "info": { "link": "1021000" },
    "stand": {
      "0": {
        "__i": "assets/images/Npc/2.png",
        "__w": 40,
        "__h": 79,
        "origin": [22, 79],
      },
    },
  }
  let npc : NxNpc = @json.from_json(src)
  inspect(npc.info.link, content="Some(\"1021000\")")
}

///|
test "parse_nx_npc_scripted_from_script_or_shop" {
  let from_script : NxNpc = @json.from_json({
    "info": { "script": { "0": { "script": "foo" } } },
    "stand": {
      "0": {
        "__i": "assets/images/Npc/3.png",
        "__w": 40,
        "__h": 79,
        "origin": [22, 79],
      },
    },
  })
  inspect(from_script.info.scripted, content="true")

  let from_shop : NxNpc = @json.from_json({
    "info": { "shop": true },
    "stand": {
      "0": {
        "__i": "assets/images/Npc/4.png",
        "__w": 40,
        "__h": 79,
        "origin": [22, 79],
      },
    },
  })
  inspect(from_shop.info.scripted, content="true")
}

///|
test "parse_nx_npc_reject_missing_animation" {
  let src : Json = { "info": { "speak": { "0": "n0" } } }
  let _ : NxNpc = @json.from_json(src) catch { _ => return }
  fail("expected parse error for missing animation")
}
