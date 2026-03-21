///|
const TEST_MAP_ID : Int = 105040300

///|
const TEST_PORTAL_ID : Int = 16

///|
const TEST_NPC_OID : Int = 100003

///|
const TEST_NPC_ID : Int = 1061005

///|
const TEST_NPC_X : Int = 765

///|
const TEST_NPC_Y : Int = -378

///|
const TEST_NPC_FH : Int = 19

///|
const TEST_QUEST_ID : Int = 2050

///|
fn parse_json_file(path : String) -> Json raise {
  @json.parse(@fs.read_file_to_string(path))
}

///|
fn load_map_root_105040300() -> Json {
  (@fs.read_file_to_string("assets/map/map1/105040300.img.json") |> @json.parse) catch {
    _ => panic()
  }
}

///|
fn join_dir(root : String, path : String) -> String {
  let normalized_root = root.strip_suffix("/").unwrap_or(root)
  let normalized_path = path.strip_prefix("/").unwrap_or(path)
  "\{normalized_root}/\{normalized_path}"
}

///|
fn get_by_path(obj : Json, path : String) -> Json {
  if path.is_empty() {
    return obj
  }
  let parts = path.split("/")
  parts.fold(init=obj, fn(acc, part) {
    match acc {
      Object(map) => map.get(part.to_string()).unwrap_or(null)
      _ => null
    }
  })
}

///|
fn load_local_node_json(root_dir : String, path : Array[String]) -> Json {
  guard path.length() > 0 else { panic() }
  let root_file = join_dir(root_dir, path[0] + ".json")
  let root_json = @json.parse(@fs.read_file_to_string(root_file)) catch {
    _ => panic()
  }
  let mut sub_path = ""
  for i = 1; i < path.length(); i = i + 1 {
    if i > 1 {
      sub_path += "/"
    }
    sub_path += path[i]
  }
  get_by_path(root_json, sub_path)
}

///|
fn load_map_runtime_105040300() -> (@physics.Physics, @map.MapInfo) {
  let root = load_map_root_105040300()
  let nx_map : @map.NxMap = @json.from_json(root) catch { _ => panic() }
  let physics = match root {
    { "foothold": foothold, .. } =>
      @physics.Physics::from_resource(
        @json.from_json(foothold) catch {
          _ => panic()
        },
      ) catch {
        _ => panic()
      }
    _ => panic()
  }

  let background_animation_sets : Map[
    String,
    Map[@map.BackgroundAnimationPath, @resource.NxAnimation],
  ] = {}
  for background in nx_map.back.0 {
    if background.bS == "" {
      continue
    }
    let key = @map.BackgroundAnimationPath::from_nx(background)
    let set_map = background_animation_sets.get_or_init(background.bS, fn() {
      {}
    })
    if not(set_map.contains(key)) {
      let anim_node = load_local_node_json("assets/map/back", [
        background.bS + ".img",
        if background.ani {
          "ani"
        } else {
          "back"
        },
        background.no.to_string(),
      ])
      set_map[key] = @json.from_json(anim_node) catch { _ => continue }
    }
  }

  let backgrounds = @map.load_backgrounds(
    nx_map.back,
    background_animation_sets,
  )
  @map.set_backgrounds(backgrounds)
  let map_info = @map.MapInfo::from_resource(
    root,
    physics.get_fht().get_walls(),
    physics.get_fht().get_borders(),
  )
  @map.set_runtime_context(map_info, physics)
  (physics, map_info)
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
      map_id: TEST_MAP_ID,
      portal_id: TEST_PORTAL_ID,
    },
    fn() { @weapon.Type::NONE },
    @job.Job::new(0, @job.Level::BEGINNER, Map::new()),
    Map::new(),
    Map::new(),
    Map::new(),
  )
  stats.set_stat(@maple_stat.Id::LEVEL, 30)
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
fn setup_ui_window2_loader_local() -> Unit {
  @resource.set_ui_window_2_loader(
    @resource.AsyncLoader::new(
      "test_local_ui_window_2",
      base_url="/assets",
      loader=@local_loader.LocalDirResourceLoader::new(
        "assets/ui/UIWindow2.img",
      ),
    ),
  )
}

///|
async fn load_quest_icon_animations() -> (
  @resource.NxAnimation,
  @resource.NxAnimation,
  @resource.NxAnimation,
) {
  setup_ui_window2_loader_local()
  let loader = @resource.get_ui_window_2_loader()
  let available_json = loader.load_resource(["QuestIcon", "0"]) catch {
    _ => panic()
  }
  let in_progress_json = loader.load_resource(["QuestIcon", "1"]) catch {
    _ => panic()
  }
  let completed_json = loader.load_resource(["QuestIcon", "2"]) catch {
    _ => panic()
  }
  (
    @json.from_json(available_json) catch {
      _ => panic()
    },
    @json.from_json(in_progress_json) catch {
      _ => panic()
    },
    @json.from_json(completed_json) catch {
      _ => panic()
    },
  )
}

///|
fn normalize_camera_limits(
  left : Double,
  right : Double,
  top : Double,
  bottom : Double,
) -> (Double, Double, Double, Double) {
  let viewport_size = @system.get_viewport_size()
  let viewport_width = viewport_size.0
  let viewport_height = viewport_size.1
  let right = if right - left < viewport_width {
    left + viewport_width
  } else {
    right
  }
  let top = if bottom - top < viewport_height {
    bottom - viewport_height
  } else {
    top
  }
  (left, right, top, bottom)
}

///|
fn setup_camera(position : @selene_math.Vec2D, map_info : @map.MapInfo) -> Unit {
  let camera_anchor = @entity.Entity::new()
  @position.positions().set(camera_anchor, @position.Position(position))
  @camera.attach_entity(camera_anchor, @selene_math.Vec2D(0.0, 0.0))
  @camera.set_follow_x(true)
  @camera.set_follow_y(true)
  let (left, right, top, bottom) = normalize_camera_limits(
    map_info.get_walls().first().to_double(),
    map_info.get_walls().second().to_double(),
    map_info.get_borders().first().to_double(),
    map_info.get_borders().second().to_double(),
  )
  @camera.set_limits(left~, right~, top~, bottom~)
  @camera.camera_system(0.016)
}

///|
fn setup_app() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(800.0)
    .with_viewport_height(540.0)
    .add_plugin(@plugins.default_plugin)
    .add_system(
      Update,
      fn(_world) { @logic_fps.logic_fps_system(@time.delta()) },
      system_name="logic_fps_system",
    )
    .add_system(
      Update,
      fn(_world) { @map.background_system(@time.delta()) },
      system_name="background_system",
    )
    .add_system(
      Update,
      fn(_world) { @map.tile_objects_system(@time.delta()) },
      system_name="tile_objects_system",
    )
    .add_system(
      Update,
      fn(_world) { @npc.map_npcs_system(@time.delta()) },
      system_name="map_npcs_system",
    )
    .add_system(
      Update,
      fn(_world) { @quest_icon.quest_icon_system(@time.delta()) },
      system_name="quest_icon_system",
    )
    .add_system(
      Update,
      fn(_world) { @npc_talk_ui.npc_talk_ui_system(@time.delta()) },
      system_name="npc_talk_ui_system",
    )
    .add_system(
      Update,
      fn(_world) { @cursor.cursor_system(@time.delta()) },
      system_name="cursor_system",
    )
    .add_system(
      Update,
      fn(_world) { @io_service.io_system(@time.delta()) },
      system_name="io_system",
    )
  @capture_app.init_app(app)
}

///|
fn run_frames(times : Int) -> Unit {
  for _ in 0..<times {
    @capture_app.run_loop(0.016)
  }
}

///|
async fn setup_npc_talk_resource_cache() -> Unit {
  setup_ui_window2_loader_local()
  @resource.set_string_loader(@local_loader.make_local_string_loader())
  @markup_text.clear_reference_data()
  @markup_text.preload_reference_data() catch {
    _ => panic()
  }
  let ui_window_2_loader = @resource.get_ui_window_2_loader()
  @npc_talk_ui.cache_npc_talk_resource(
    @npc_talk_ui.NpcTalkResource::from_resource(
      ui_window_2_loader.load_resource(["UtilDlgEx"]) catch {
        _ => panic()
      },
    ) catch {
      _ => panic()
    },
  )
}

///|
fn create_map_npcs(physics : @physics.Physics) -> @npc.MapNpcs {
  let npc_loader = @resource.AsyncLoader::new(
    "test_npc",
    loader=@local_loader.LocalDirResourceLoader::new("assets/Npc"),
    base_url="/assets",
  )
  let string_loader = @resource.AsyncLoader::new(
    "test_string",
    loader=@local_loader.LocalDirResourceLoader::new("assets/String"),
    base_url="/assets",
  )
  let map_npcs = @npc.MapNpcs::new(
    @npc_talk_ui.open_npc_talk_ui,
    npc_loader~,
    string_loader~,
  )
  @npc.set_npcs({ map_npcs, physics })
  map_npcs
}

///|
fn spawn_target_npc(map_npcs : @npc.MapNpcs) -> Unit {
  map_npcs.apply_spawn_npc_controller_message({
    mode: 1,
    oid: TEST_NPC_OID,
    id: TEST_NPC_ID,
    x: TEST_NPC_X,
    y: TEST_NPC_Y,
    flip: false,
    fh: TEST_NPC_FH,
  })
}

///|
fn find_target_anchor() -> @npc.NpcAnchor? {
  for anchor in @npc.list_npc_anchors() {
    if anchor.oid == TEST_NPC_OID && anchor.npc_id == TEST_NPC_ID {
      return Some(anchor)
    }
  }
  None
}

///|
async fn wait_target_npc_loaded() -> @npc.NpcAnchor {
  for _ in 0..<240 {
    run_frames(1)
    @async.sleep(0)
    match find_target_anchor() {
      Some(anchor) => return anchor
      None => ()
    }
  }
  panic()
}

///|
fn collect_sprite_zindices(path_contains : String) -> Array[Int] {
  let zs : Array[Int] = []
  for _, sprite in @sprite.sprites() {
    match @test_snapshots.DebugSprite(sprite).to_json() {
      {
        "draw": [
          "Animation",
          { "current": { "sprite_path": String(path), .. }, .. },
        ],
        ..
      } if path.contains(path_contains) => zs.push(sprite.zindex)
      _ => ()
    }
  }
  zs.sort()
  zs
}

///|
fn intersects(
  a_left : Int,
  a_top : Int,
  a_right : Int,
  a_bottom : Int,
  b_left : Int,
  b_top : Int,
  b_right : Int,
  b_bottom : Int,
) -> Bool {
  a_left < b_right && a_right > b_left && a_top < b_bottom && a_bottom > b_top
}

///|
fn quest_icon_click_pos(anchor : @npc.NpcAnchor) -> @selene_math.Vec2D {
  let camera_pos = @camera.get_position()
  let view_x = -camera_pos[@selene_math.X].to_int()
  let view_y = -camera_pos[@selene_math.Y].to_int()
  let npc_pos = anchor.npc_object.get_position()
  let icon_x = npc_pos.x + view_x
  let icon_y = npc_pos.y + view_y - 96
  @selene_math.Vec2D(icon_x.to_double(), (icon_y - 8).to_double())
}

///|
fn setup_quest_icon_context() -> Unit {
  let revision = Ref::new(1)
  @quest_icon.set_context(
    fn(npc_id) {
      if npc_id == TEST_NPC_ID {
        Some({
          npc_id,
          quest_id: TEST_QUEST_ID,
          state: @quest.QuestIconState::AVAILABLE,
        })
      } else {
        None
      }
    },
    fn(quest_id, npc_id) {
      if quest_id != TEST_QUEST_ID || npc_id != TEST_NPC_ID {
        return None
      }
      Some({
        npc_id,
        speaker: @npc.Speaker::NPC_LEFT,
        str: "[Quest] Blue Mushroom\n请确认对话框层级与位置。",
        talk_action: @npc.TalkAction::SEND_OK(fn(_ok) {  }),
      })
    },
    fn() { revision.val },
  )
}

///|
fn teardown_scene() -> Unit {
  @npc_talk_ui.close_npc_talk_ui()
  @quest_icon.clear_context()
  @npc.clear_map_npcs()
  @map.clear_runtime_context()
  @player.player_ref.val = None
  @character.clear_character_registry()
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @game_state.game_state.phase = @game_state.GamePhase::SelectCharacter
}

///|
async fn setup_scene() -> @npc.NpcAnchor {
  @npc_talk_ui.close_npc_talk_ui()
  @quest_icon.clear_context()
  @npc.clear_map_npcs()
  @map.clear_runtime_context()
  @entity.iter_entities().each(fn(entity) { entity.destroy() })
  @sprite.sprites().clear()
  @game_state.game_state.phase = @game_state.GamePhase::GameActive(
    map_id=TEST_MAP_ID,
    portal_id=TEST_PORTAL_ID,
  )
  @inputs.apply_input_snapshot(@inputs.empty_input_snapshot())
  @inputs.advanced_key_system(0.0)
  @inputs.mouse.pos = @selene_math.Vec2D(0.0, 0.0)

  setup_app()
  setup_npc_talk_resource_cache()
  setup_test_player() catch {
    _ => panic()
  }

  let (physics, map_info) = load_map_runtime_105040300()
  setup_camera(
    @selene_math.Vec2D(TEST_NPC_X.to_double(), TEST_NPC_Y.to_double()),
    map_info,
  )

  let map_npcs = create_map_npcs(physics)
  spawn_target_npc(map_npcs)

  let (available, in_progress, completed) = load_quest_icon_animations()
  @quest_icon.set_resources_for_test(available, in_progress, completed)
  setup_quest_icon_context()

  let anchor = wait_target_npc_loaded()
  run_frames(8)
  anchor
}

///|
async test "npc quest talk ui renders over npc and under cursor on map 105040300" {
  defer teardown_scene()
  defer @entity.iter_entities().each(fn(entity) { entity.destroy() })
  defer @sprite.sprites().clear()

  let anchor = setup_scene()
  let click_pos = quest_icon_click_pos(anchor)
  @inputs.mouse.pos = click_pos
  @inputs.just_pressed_mouse.left_button = true
  @quest_icon.quest_icon_system(0.016)
  @inputs.just_pressed_mouse.left_button = false

  run_frames(10)

  let desc = @npc_talk_ui.describe_npc_talk_ui()
  let (
    window_left,
    window_top,
    window_right,
    window_bottom,
    ui_z_min,
    ui_z_max,
    window_x,
    body_height,
  ) = match desc {
    {
      "open": true,
      "window_pos": { "x": Number(window_x, ..), .. },
      "window_rect": {
        "left": Number(left, ..),
        "top": Number(top, ..),
        "right": Number(right, ..),
        "bottom": Number(bottom, ..),
        ..
      },
      "z_range": { "min": Number(z_min, ..), "max": Number(z_max, ..), .. },
      "body_height": Number(body_height, ..),
      ..
    } =>
      (
        left.to_int(),
        top.to_int(),
        right.to_int(),
        bottom.to_int(),
        z_min.to_int(),
        z_max.to_int(),
        window_x.to_int(),
        body_height.to_int(),
      )
    _ => fail("npc talk ui should be open after quest icon click")
  }

  inspect(window_left >= 0 && window_top >= 0, content="true")
  inspect(window_right <= 800 && window_bottom <= 540, content="true")

  let npc_zs = collect_sprite_zindices("/Npc/")
  let cursor_zs = collect_sprite_zindices("/ui/cursor/")
  inspect(npc_zs.length() > 0, content="true")
  inspect(cursor_zs.length() > 0, content="true")
  let npc_max_z = npc_zs[npc_zs.length() - 1]
  let cursor_min_z = cursor_zs[0]
  inspect(npc_max_z < ui_z_min, content="true")
  inspect(ui_z_max < cursor_min_z, content="true")

  let mut window_ui_image_count = 0
  let mut window_ui_image_region_count = 0
  for entity, _ in @selene_ui.ui_images() {
    guard @selene_ui.global_ui_nodes().get(entity) is Some(global_node) else {
      continue
    }
    guard @selene_ui.z_indexes().get(entity) is Some(z) else { continue }
    let left = global_node.screen_rect.position[@selene_math.X].to_int()
    let top = global_node.screen_rect.position[@selene_math.Y].to_int()
    let right = left + global_node.screen_rect.size[@selene_math.X].to_int()
    let bottom = top + global_node.screen_rect.size[@selene_math.Y].to_int()
    guard intersects(
      left, top, right, bottom, window_left, window_top, window_right, window_bottom,
    ) else {
      continue
    }
    guard z.value >= ui_z_min && z.value <= ui_z_max else { continue }
    window_ui_image_count += 1
    if @selene_ui.ui_image_regions().contains(entity) {
      window_ui_image_region_count += 1
    }
  }
  inspect(window_ui_image_count >= 4, content="true")
  inspect(window_ui_image_region_count >= 4, content="true")

  json_inspect(desc, content={
    "open": true,
    "body_lines": [
      "[Quest] Blue Mushroom", "请确认对话框层级与位置。",
    ],
    "selections": [],
    "button_count": 2,
    "choice_area_count": 0,
    "window_pos": { "x": 141, "y": 202 },
    "window_size": { "w": 519, "h": 148 },
    "window_rect": { "left": 141, "top": 202, "right": 660, "bottom": 350 },
    "z_range": { "min": 100100, "max": 100108 },
    "body_height": 76,
  })

  @capture_app.snapshot(
    "src/test/npc_talk_ui_test/__snapshot__/npc_quest_talk_ui_scene_105040300_1061005_quest2050.png",
    expect="The screenshot must clearly show a full NPC talk UI window frame (top/fill/bottom panels and buttons), not just plain text. The dialog window should be visibly rendered over the map scene.",
  )

  let close_hover_pos = @selene_math.Vec2D(
    (window_x + 20).to_double(),
    (window_top + body_height + 56).to_double(),
  )
  @inputs.mouse.pos = close_hover_pos
  @inputs.mouse.left_button = false
  run_frames(2)
  let mut hovered_buttons = 0
  for entity, interaction in @selene_ui.interactions() {
    if interaction is @selene_ui.Interaction::Hovered &&
      @selene_ui.buttons().contains(entity) {
      hovered_buttons += 1
    }
  }
  inspect(hovered_buttons > 0, content="true")

  @inputs.mouse.left_button = true
  run_frames(1)
  let mut pressed_buttons = 0
  for entity, interaction in @selene_ui.interactions() {
    if interaction is @selene_ui.Interaction::Pressed &&
      @selene_ui.buttons().contains(entity) {
      pressed_buttons += 1
    }
  }
  inspect(pressed_buttons > 0, content="true")
  @inputs.mouse.left_button = false
}
