///|
test "resolve_ref keeps absolute path canonical" {
  inspect(
    resolve_ref(
      "/assets/Mob/1210102.img/mx.json", "/assets/./Mob/1210102.img/animations/../stand.json",
    ),
    content="/assets/Mob/1210102.img/stand.json",
  )
}

///|
test "resolve_ref resolves relative path by base file directory" {
  inspect(
    resolve_ref("Mob/1210102.img/mx.json", "animations\\stand.json"),
    content="/assets/Mob/1210102.img/animations/stand.json",
  )
}

///|
test "resolve_ref handles parent directory segments" {
  inspect(
    resolve_ref(
      "/assets/Npc/Npc/1021000.img/mx.json", "../shared/../1021000.img/animation.json",
    ),
    content="/assets/Npc/Npc/1021000.img/animation.json",
  )
}

///|
test "resolve_ref is idempotent after canonicalization" {
  let base = "/assets/Mob/1210102.img/mx.json"
  let first = resolve_ref(base, "animations/stand.json")
  let second = resolve_ref(base, first)
  inspect(second, content=first)
}

///|
test "resolve_ref_from_dir resolves by directory semantics" {
  inspect(
    resolve_ref_from_dir("/assets/Mob/1210102.img/", "animations\\stand.json"),
    content="/assets/Mob/1210102.img/animations/stand.json",
  )
}

///|
test "resolve_ref_from_dir supports parent segments" {
  inspect(
    resolve_ref_from_dir(
      "/assets/skill/110.img", "../111.img/animations/hit0.json",
    ),
    content="/assets/skill/111.img/animations/hit0.json",
  )
}

///|
test "resolve_resource_path keeps mob source root behavior" {
  inspect(
    resolve_resource_path("mob", "Mob/1210102.img/mx.json"),
    content="/assets/mob/Mob/1210102.img/mx.json",
  )
}

///|
test "resolve_resource_path keeps skill source root behavior" {
  inspect(
    resolve_resource_path("skill", "110.img.json"),
    content="/assets/skill/110.img.json",
  )
}

///|
test "panic path resolver should reject test_mob source" {
  ignore(resolve_resource_path("test_mob", "noop"))
}

///|
test "panic path resolver should reject mock_string source" {
  ignore(resolve_resource_path("mock_string", "noop"))
}

///|
test "panic path resolver should reject counting_item_loader source" {
  ignore(resolve_resource_path("counting_item_loader", "noop"))
}

///|
test "panic path resolver should reject dummy source" {
  ignore(resolve_resource_path("dummy", "noop"))
}
