///|
test "resolve_ref keeps resolved asset path canonical" {
  inspect(
    resolve_ref(
      "assets/Mob/1210102.img/mx.json", "assets/./Mob/1210102.img/animations/../stand.json",
    ),
    content="assets/Mob/1210102.img/stand.json",
  )
}

///|
test "resolve_ref resolves relative path by base file directory" {
  inspect(
    resolve_ref("Mob/1210102.img/mx.json", "animations\\stand.json"),
    content="assets/Mob/1210102.img/animations/stand.json",
  )
}

///|
test "resolve_ref handles parent directory segments" {
  inspect(
    resolve_ref(
      "assets/Npc/Npc/1021000.img/mx.json", "../shared/../1021000.img/animation.json",
    ),
    content="assets/Npc/Npc/1021000.img/animation.json",
  )
}

///|
test "resolve_ref is idempotent after canonicalization" {
  let base = "assets/Mob/1210102.img/mx.json"
  let first = resolve_ref(base, "animations/stand.json")
  let second = resolve_ref(base, first)
  inspect(second, content=first)
}

///|
test "resolve_ref_from_dir resolves by directory semantics" {
  inspect(
    resolve_ref_from_dir("assets/Mob/1210102.img/", "animations\\stand.json"),
    content="assets/Mob/1210102.img/animations/stand.json",
  )
}

///|
test "resolve_ref_from_dir supports parent segments" {
  inspect(
    resolve_ref_from_dir(
      "assets/Skill/110.img", "../111.img/animations/hit0.json",
    ),
    content="assets/Skill/111.img/animations/hit0.json",
  )
}

///|
test "resolve_ref resolves tiled external tileset path" {
  inspect(
    resolve_ref(
      "assets/Map/tiles/100030000.img.tmj", "../tilesets/bg_midForest.tsj",
    ),
    content="assets/Map/tilesets/bg_midForest.tsj",
  )
}

///|
test "resolve_resource_path keeps mob source root behavior" {
  inspect(
    resolve_resource_path("mob", "Mob/1210102.img/mx.json"),
    content="assets/mob/Mob/1210102.img/mx.json",
  )
}

///|
test "resolve_resource_path keeps skill source root behavior" {
  inspect(
    resolve_resource_path("skill", "110.img.json"),
    content="assets/Skill/110.img.json",
  )
}

///|
test "resolve_json_resource_path splits item bundle and node path" {
  let (file_path, node_path) = resolve_json_resource_path(
    "item", "Consume/0206.img/02060000",
  )
  inspect(file_path, content="assets/Item/Consume/0206.img.json")
  json_inspect(node_path, content=["02060000"])
}

///|
test "resolve_json_resource_path keeps explicit json path as file path" {
  let (file_path, node_path) = resolve_json_resource_path(
    "npc", "assets/Npc/Npc/1103002.img/mx.json",
  )
  inspect(file_path, content="assets/Npc/Npc/1103002.img/mx.json")
  json_inspect(node_path, content=[])
}

///|
test "resolve_json_resource_path resolves ui bundle node path" {
  let (file_path, node_path) = resolve_json_resource_path(
    "ui_window_2", "ToolTip/WorldMap",
  )
  inspect(file_path, content="assets/UI/UIWindow2.img/ToolTip.json")
  json_inspect(node_path, content=["WorldMap"])
}

///|
test "resolve_json_resource_path resolves effect leaf files" {
  let (file_path, node_path) = resolve_json_resource_path(
    "effect", "BasicEff.img/Teleport",
  )
  inspect(file_path, content="assets/Effect/BasicEff.img/Teleport.json")
  json_inspect(node_path, content=[])
}
