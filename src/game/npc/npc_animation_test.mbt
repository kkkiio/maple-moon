///|
test "NPC starts another ambient cycle after its clip finishes" {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  defer @asset.set_io(fn(_path) { None })
  try! @res.configure_packs([
    ("base", "assets/base"),
    ("dlc-victoria", "assets/dlc-victoria"),
  ])
  defer @res.clear_mounts()
  defer clear_map_npcs()

  let physics = @physics.empty_physics()
  let map_npcs = MapNpcs::MapNpcs(fn(_args) {  }, fn() { false })
  set_npcs({ map_npcs, physics })
  map_npcs.apply_spawn_npc_message(@server_proto.NpcSpawnMessage::{
    oid: 1,
    id: 1081001,
    x: 0,
    y: 0,
    flip: false,
    fh: 0,
  })
  map_npcs.update(physics)
  guard list_npc_anchors() is [anchor] else {
    fail("expected one loaded NPC anchor")
  }
  @debug.debug_inspect(
    anchor.ambient_states,
    content=(
      #|["stand"]
    ),
  )
  guard @selene_animation.animation_players().get(anchor.entity) is Some(player) else {
    fail("loaded NPC must own an animation player")
  }
  let initially_finished = player.all_finished()
  @selene_animation.animation_player_system(0.11)
  let finished_after_clip = player.all_finished()
  map_npcs.update(physics)
  let finished_after_npc_update = player.all_finished()

  @debug.debug_inspect(
    (initially_finished, finished_after_clip, finished_after_npc_update),
    content=(
      #|(false, true, false)
    ),
  )
}

///|
test "NPC ambient states exclude shop presentation" {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  defer @asset.set_io(fn(_path) { None })
  try! @res.configure_packs([
    ("base", "assets/base"),
    ("dlc-victoria", "assets/dlc-victoria"),
  ])
  defer @res.clear_mounts()
  defer clear_map_npcs()

  let physics = @physics.empty_physics()
  let map_npcs = MapNpcs::MapNpcs(fn(_args) {  }, fn() { false })
  set_npcs({ map_npcs, physics })
  map_npcs.apply_spawn_npc_message(@server_proto.NpcSpawnMessage::{
    oid: 1,
    id: 1061001,
    x: 0,
    y: 0,
    flip: false,
    fh: 0,
  })
  map_npcs.update(physics)
  guard list_npc_anchors() is [anchor] else {
    fail("expected one loaded NPC anchor")
  }
  @debug.debug_inspect(
    anchor.ambient_states,
    content=(
      #|["stand"]
    ),
  )
}

///|
test "NPC ambient states retain expressive animations" {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  defer @asset.set_io(fn(_path) { None })
  try! @res.configure_packs([
    ("base", "assets/base"),
    ("dlc-victoria", "assets/dlc-victoria"),
  ])
  defer @res.clear_mounts()
  defer clear_map_npcs()

  let physics = @physics.empty_physics()
  let map_npcs = MapNpcs::MapNpcs(fn(_args) {  }, fn() { false })
  set_npcs({ map_npcs, physics })
  map_npcs.apply_spawn_npc_message(@server_proto.NpcSpawnMessage::{
    oid: 1,
    id: 9201088,
    x: 0,
    y: 0,
    flip: false,
    fh: 0,
  })
  map_npcs.update(physics)
  guard list_npc_anchors() is [anchor] else {
    fail("expected one loaded NPC anchor")
  }
  @debug.debug_inspect(
    anchor.ambient_states,
    content=(
      #|["say0", "say1", "stand"]
    ),
  )
}
