///|
fn parse_json_file(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
fn make_test_look() -> @char_look.CharLook raise {
  let entity = @entity.Entity::new()
  let bodynode = parse_json_file("assets/Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = parse_json_file("assets/Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @types.BodyDrawInfo::new(
    stance_bodys_map.0,
    stance_heads_map.0,
  )
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    parse_json_file("assets/Character/Hair/00030000.img.json"),
  )
  @char_look.CharLook::new(
    entity,
    {},
    @char_look.FullBody::new(
      0,
      draw_info,
      stance_bodys_map.0,
      stance_heads_map.0,
    ),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @char_look.Face::new(
      20000,
      parse_json_file("assets/Character/Face/00020000.img.json"),
    ),
    draw_info,
  )
}

///|
fn make_test_player() -> @player.Player raise {
  let look = make_test_look()
  let stats = @char_stats.CharStats::new(
    @server_proto.StatsEntry::{
      name: "Maple",
      female: false,
      stats: @resource.EnumMap::default(),
      i64stats: @resource.EnumMap::default(),
      map_id: 100000000,
      portal_id: 0,
    },
    fn() { @weapon.Type::NONE },
    @job.Job::new(0, @job.Level::BEGINNER, Map::new()),
    Map::new(),
    Map::new(),
    Map::new(),
  )
  stats.set_stat(@maple_stat.Id::LEVEL, 200)
  @player.Player::new(
    look.get_root_entity(),
    1001,
    "Maple",
    @legacy_types.MockInventory::default(),
    look,
    stats,
  )
}

///|
fn list_phase0_npc_ids_from_raw(raw : Json) -> Array[Int] {
  let npc_ids = []
  guard raw is { "Check.img": Object(check_img), .. } else { return npc_ids }
  for _, quest_json in check_img {
    guard quest_json is Object(phase_map) else { continue }
    guard phase_map.get("0") is Some(Object(phase0)) else { continue }
    guard phase0.get("npc") is Some(Number(npc_id, ..)) else { continue }
    npc_ids.push(npc_id.to_int())
  }
  npc_ids
}

///|
async test "select demo quest from real quest assets" {
  defer {
    @player.player_ref.val = None
  }
  defer @character.clear_character_registry()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })

  setup_ui_window2_loader_local()
  @resource.set_quest_loader(@local_loader.make_local_quest_loader())
  let raw = parse_json_file("assets/Quest/nx.json") catch { _ => panic() }
  let quest_module = @quest.Module::load(@inventory.Inventory::new(), fn(
    _args,
  ) {

  })
  @quest.set_active_module(quest_module)
  let player = make_test_player() catch { _ => panic() }
  @player.set_player(player)
  @quest.bind_player(player)
  @quest.handle_player_quest_info(@server_proto.PlayerQuestLogInfo::default())

  let npc_ids = list_phase0_npc_ids_from_raw(raw)
  let selection = @quest.select_demo_quest_by_npcs(npc_ids)
  inspect(selection is Some(_), content="true")
}
