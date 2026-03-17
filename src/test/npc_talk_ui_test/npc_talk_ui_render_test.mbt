///|
fn parse_json_file(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
async fn get_npc_dialogue_text(npc_id : Int, key : String) -> String {
  let string_loader = @local_loader.make_local_string_loader()
  let src = string_loader.load_resource(["Npc.img", npc_id.to_string(), key])
  match src {
    String(text) => text
    _ => panic()
  }
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
fn setup_test_player() -> Unit raise {
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
  stats.set_stat(@maple_stat.Id::LEVEL, 12)
  let player = @player.Player::new(
    look.get_root_entity(),
    1001,
    "Maple",
    @legacy_types.MockInventory::default(),
    look,
    stats,
  )
  @player.set_player(player)
}

///|
async fn setup_npc_talk_scene(args : @npc.TalkArgs) -> Unit {
  @npc_talk_ui.close_npc_talk_ui()
  @entity.iter_entities().each(fn(entity) { entity.destroy() })
  @sprite.sprites.clear()
  @game_state.game_state.phase = @game_state.GamePhase::GameActive(
    map_id=100000000,
    portal_id=0,
  )
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.mouse.pos = @selene_math.Vec2D(0.0, 0.0)
  @capture_app.init_app(
    @system.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      @npc_talk_ui.npc_talk_ui_system,
      system_name="npc_talk_ui_system",
    ),
  )
  @resource.set_ui_window_2_loader(
    @resource.AsyncLoader::new(
      "test_local_ui_window_2",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new(
        "assets/ui/UIWindow2.img",
      ),
    ),
  )
  @resource.set_string_loader(@local_loader.make_local_string_loader())
  @markup_text.clear_reference_data()
  @markup_text.preload_reference_data()
  @npc_talk_ui.cache_npc_talk_resource(
    @npc_talk_ui.NpcTalkResource::from_resource(
      parse_json_file("assets/ui/UIWindow2.img/UtilDlgEx.json") catch {
        _ => panic()
      },
    ) catch {
      _ => panic()
    },
  )
  setup_test_player() catch {
    _ => panic()
  }
  @npc_talk_ui.open_npc_talk_ui(args)
  for _ in 0..<6 {
    @capture_app.run_loop(0.016)
  }
}

///|
fn teardown_npc_talk_scene() -> Unit {
  @npc_talk_ui.close_npc_talk_ui()
  @player.player_ref.val = None
  @character.clear_character_registry()
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @game_state.game_state.phase = @game_state.GamePhase::SelectCharacter
}

///|
fn assert_npc_talk_snapshot(name : String) -> Unit raise {
  @capture_app.snapshot("src/test/npc_talk_ui_test/__snapshot__/\{name}.png")
}

///|
async test "npc talk ui renders dialog snapshots" {
  defer teardown_npc_talk_scene()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites.clear()
  let npc_1002001_d1 = get_npc_dialogue_text(1002001, "d1")
  let npc_1012102_d0 = get_npc_dialogue_text(1012102, "d0")
  let npc_1061003_d0 = get_npc_dialogue_text(1061003, "d0")
  setup_npc_talk_scene({
    npc_id: 1002001,
    speaker: @npc.Speaker::NPC_LEFT,
    str: npc_1002001_d1,
    talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
  })
  json_inspect(@npc_talk_ui.describe_npc_talk_ui(), content={
    "open": true,
    "body_lines": [
      "Oh~ So it seems that you have delievered Weird Medicine to Maya...! Thanks. Now Maya can get better now. huh? Sparkling Rock It is still very beautiful~",
    ],
    "selections": [],
    "button_count": 2,
    "choice_area_count": 0,
    "window_pos": { "x": 141, "y": 202 },
    "body_height": 76,
  })
  assert_npc_talk_snapshot("npc_talk_ui_real_1002001_d1")
  teardown_npc_talk_scene()
  setup_npc_talk_scene({
    npc_id: 1012102,
    speaker: @npc.Speaker::NPC_LEFT,
    str: npc_1012102_d0,
    talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
  })
  json_inspect(@npc_talk_ui.describe_npc_talk_ui(), content={
    "open": true,
    "body_lines": [
      "Ah~! It is really getting to me!!! Blue Mushroom... Oh... Are you a stranger?",
    ],
    "selections": [],
    "button_count": 2,
    "choice_area_count": 0,
    "window_pos": { "x": 141, "y": 202 },
    "body_height": 76,
  })
  assert_npc_talk_snapshot("npc_talk_ui_real_1012102_d0")
  teardown_npc_talk_scene()
  setup_npc_talk_scene({
    npc_id: 1061003,
    speaker: @npc.Speaker::NPC_LEFT,
    str: npc_1061003_d0,
    talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
  })
  json_inspect(@npc_talk_ui.describe_npc_talk_ui(), content={
    "open": true,
    "body_lines": [
      "Welcome to the VIP sauna of the Sleepywood Hotel. Actually I need some help here ...",
    ],
    "selections": [],
    "button_count": 2,
    "choice_area_count": 0,
    "window_pos": { "x": 141, "y": 202 },
    "body_height": 76,
  })
  assert_npc_talk_snapshot("npc_talk_ui_real_1061003_d0")
}
