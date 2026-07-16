///|
fn init {
  @asset.set_io(fn(path) {
    Some(@fs.read_file_to_bytes(path)) catch {
      _ => None
    }
  })
  try! @res.configure_packs([("base", "assets/base")])
}

///|
let rope_hold_map_id = 105040000

///|
let rope_hold_empty_air_x = -586

///|
let rope_hold_empty_air_top = -1856

///|
let rope_hold_empty_air_bottom = -1613

///|
let rope_exit_platform_x = -645

///|
let rope_exit_platform_top = -1993

///|
let rope_exit_platform_bottom = -1768

///|
fn parse_json_file(path : String) -> Json {
  @res.require_json(path)
}

///|
fn make_test_look() -> @char_look.CharLook raise {
  let entity = @entity.Entity()
  let bodynode = parse_json_file("res://Character/Body/00002000.img.json")
  let stance_bodys_map : @char_look.NxStanceLooks[@types.NxStanceBody] = @json.from_json(
    bodynode,
  )
  let headnode = parse_json_file("res://Character/Body/00012000.img.json")
  let stance_heads_map : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    headnode,
  )
  let draw_info = @cb.BodyDrawInfo(stance_bodys_map.0, stance_heads_map.0)
  let hair_node : @char_look.NxStanceLooks[@types.NxMultiPartFrame] = @json.from_json(
    parse_json_file("res://Character/Hair/00030000.img.json"),
  )
  @cp.CharLook(
    entity,
    Map([]),
    @cp.FullBody(0, draw_info, stance_bodys_map.0, stance_heads_map.0),
    @char_look.Hair::parse(0, hair_node, draw_info),
    @cp.Face(20000, parse_json_file("res://Character/Face/00020000.img.json")),
    draw_info,
  )
}

///|
fn make_test_player(oid : Int) -> @player.Player raise {
  let look = make_test_look()
  let stats : @char_stats.CharStats = CharStats(
    Default::default(),
    fn() { @weapon.Type::NONE },
    Job(0, @job.Level::BEGINNER, Map([])),
    Map([]),
    Map([]),
    Map([]),
  )
  Player(
    look.get_root_entity(),
    oid,
    "ControllerRopeTester",
    @legacy_types.MockInventory::{  },
    look,
    stats,
  )
}

///|
fn load_map_runtime(map_id : Int) -> (@map.MapInfo, @physics.Physics) raise {
  let prefix = map_id / 100000000
  let mx_address = "res://Map/Map\{prefix}/\{map_id}.img.mx.json"
  let (_, tiled_map) = @res.load_tiled_map_from_mx(mx_address)
  let foothold_tree = @map.from_tiled_foothold_tree(tiled_map)
  let physics = @physics.Physics::from_resource(foothold_tree)
  let map_info = @map.MapInfo::from_tiled_map(
    tiled_map,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  (map_info, physics)
}

///|
fn install_test_keymap() -> Unit {
  let keymap : @keymap.Keymap = Map([])
  keymap[@inputs.Code::ArrowUp] = @keymap.Action::BASIC(
    @keymap.BasicActionId::MOVE_UP,
  )
  keymap[@inputs.Code::ArrowDown] = @keymap.Action::BASIC(
    @keymap.BasicActionId::MOVE_DOWN,
  )
  keymap[@inputs.Code::ArrowLeft] = @keymap.Action::BASIC(
    @keymap.BasicActionId::MOVE_LEFT,
  )
  keymap[@inputs.Code::ArrowRight] = @keymap.Action::BASIC(
    @keymap.BasicActionId::MOVE_RIGHT,
  )
  keymap[@inputs.Code::Space] = @keymap.Action::BASIC(
    @keymap.BasicActionId::JUMP,
  )
  @keymap.set_keymap(keymap)
}

///|
fn setup_controller_env(
  map_id : Int,
  start_x : Int,
  start_y : Int,
) -> (@player.Player, @map.MapInfo) raise {
  let (map_info, physics) = load_map_runtime(map_id)
  @map.set_runtime_context(map_info, physics)
  @game_state.init_state(
    @game_state.GamePhase::GameActive(map_id~, portal_id=0),
  )
  install_test_keymap()
  apply_keyboard_snapshot([])
  let player = make_test_player(map_id + start_x.abs() + start_y.abs())
  player.set_position(start_x, start_y)
  @player.set_player(player)
  (player, map_info)
}

///|
fn teardown_controller_env() -> Unit {
  apply_keyboard_snapshot([])
  @keymap.set_keymap(Map([]))
  @map.clear_runtime_context()
  @game_state.init_state(@game_state.GamePhase::SelectCharacter)
}

///|
fn apply_keyboard_snapshot(pressed : Array[@inputs.Code]) -> Unit {
  let snapshot = @inputs.empty_input_snapshot()
  for code in pressed {
    snapshot.pressed_keys.add(code)
  }
  @inputs.apply_input_snapshot(snapshot)
  @inputs.advanced_key_system(0.0)
}

///|
fn advance_controller_frames(
  frames : Int,
  pressed : Array[@inputs.Code],
  just_pressed? : Array[@inputs.Code] = [],
) -> Unit {
  for frame in 0..<frames {
    let frame_pressed = if frame == 0 && just_pressed.length() > 0 {
      just_pressed
    } else {
      pressed
    }
    apply_keyboard_snapshot(frame_pressed)
    player_controller_input_system(@ecs.require_current_world())
    player_controller_fixed_system(@ecs.require_current_world())
  }
  apply_keyboard_snapshot([])
}

///|
fn find_rope_or_fail(map_info : @map.MapInfo, x : Int, y : Int) -> @map.Ladder {
  guard map_info.find_ladder(Point(x, y), true) is Some(rope) else {
    abort("unexpected input state in controller test")
  }
  rope
}

///|
test "105040000 rope 10 should hold at top when climbing into empty air" {
  let start_y = rope_hold_empty_air_bottom - 20
  let (player, map_info) = setup_controller_env(
    rope_hold_map_id, rope_hold_empty_air_x, start_y,
  )
  let character = @combat_system.CombatCharacter::get_character(player)
  let rope = find_rope_or_fail(map_info, rope_hold_empty_air_x, start_y)

  advance_controller_frames(280, [@inputs.Code::ArrowUp], just_pressed=[
    @inputs.Code::ArrowUp,
  ])
  let state = character.get_state()
  let y = character.get_phobj().get_y()
  debug_inspect(
    state,
    content=(
      #|ROPE
    ),
  )
  assert_eq(y, rope_hold_empty_air_top)
  let current_rope = player
    .get_ladder()
    .unwrap_or_error(Failure::Failure("expected to remain on rope"))
  assert_eq(current_rope.get_x(), rope_hold_empty_air_x)

  advance_controller_frames(5, [@inputs.Code::ArrowUp])
  debug_inspect(
    character.get_state(),
    content=(
      #|ROPE
    ),
  )
  assert_eq(character.get_phobj().get_y(), rope.get_top())
  teardown_controller_env()
}

///|
test "105040000 rope 11 should exit rope onto platform" {
  let start_y = rope_exit_platform_bottom - 20
  let (player, _map_info) = setup_controller_env(
    rope_hold_map_id, rope_exit_platform_x, start_y,
  )
  let character = @combat_system.CombatCharacter::get_character(player)

  advance_controller_frames(280, [@inputs.Code::ArrowUp], just_pressed=[
    @inputs.Code::ArrowUp,
  ])

  assert_true(character.get_state() != @character.CharState::ROPE)
  assert_true(character.get_state() != @character.CharState::FALL)
  assert_true(character.get_phobj().is_on_ground())
  assert_true(character.get_phobj().get_y() <= rope_exit_platform_top)
  teardown_controller_env()
}

///|
test "rope bottom exit still falls" {
  let start_y = rope_hold_empty_air_bottom - 60
  let (player, _map_info) = setup_controller_env(
    rope_hold_map_id, rope_hold_empty_air_x, start_y,
  )
  let character = @combat_system.CombatCharacter::get_character(player)

  advance_controller_frames(120, [@inputs.Code::ArrowDown], just_pressed=[
    @inputs.Code::ArrowDown,
  ])

  match player.get_ladder() {
    Some(_) => fail("expected to leave rope from the bottom")
    None => ()
  }
  assert_true(character.get_state() != @character.CharState::ROPE)
  assert_true(character.get_state() != @character.CharState::LADDER)
  assert_true(character.get_phobj().get_y() > rope_hold_empty_air_bottom)
  teardown_controller_env()
}

///|
test "held at empty-air top can still jump off" {
  let start_y = rope_hold_empty_air_bottom - 20
  let (player, _map_info) = setup_controller_env(
    rope_hold_map_id, rope_hold_empty_air_x, start_y,
  )
  let character = @combat_system.CombatCharacter::get_character(player)

  advance_controller_frames(280, [@inputs.Code::ArrowUp], just_pressed=[
    @inputs.Code::ArrowUp,
  ])
  debug_inspect(
    character.get_state(),
    content=(
      #|ROPE
    ),
  )
  advance_controller_frames(1, [@inputs.Code::ArrowLeft, @inputs.Code::Space], just_pressed=[
    @inputs.Code::ArrowLeft,
    @inputs.Code::Space,
  ])

  match player.get_ladder() {
    Some(_) => fail("expected jump to leave rope")
    None => ()
  }
  assert_true(character.get_state() != @character.CharState::ROPE)
  assert_true(character.get_phobj().get_hspeed() < 0.0)
  assert_true(character.get_phobj().get_vspeed() < 0.0)
  teardown_controller_env()
}
