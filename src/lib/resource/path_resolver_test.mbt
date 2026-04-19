///|
test "resolve_ref keeps absolute path canonical" {
  inspect(
    resolve_ref(
      "/assets/Mob/1210102.img/mx.json",
      "/assets/./Mob/1210102.img/animations/../stand.json",
    ),
    content="/assets/Mob/1210102.img/stand.json",
  )
}

///|
test "resolve_ref resolves relative path by base file directory" {
  inspect(
    resolve_ref(
      "Mob/1210102.img/mx.json",
      "animations\\stand.json",
    ),
    content="/assets/Mob/1210102.img/animations/stand.json",
  )
}

///|
test "resolve_ref handles parent directory segments" {
  inspect(
    resolve_ref(
      "/assets/Npc/Npc/1021000.img/mx.json",
      "../shared/../1021000.img/animation.json",
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
